-- 对账：第一张“每日收入构成”的回流收入，拆为回流当日 vs 回流后续收入
WITH
DateConfig AS (
    SELECT DATE '2026-07-10' AS start_date, DATE '2026-07-16' AS end_date
),
UserBlacklist AS (
    SELECT DISTINCT "#varchar_id" AS "#account_id"
    FROM user_result_cluster_20
    WHERE cluster_name IN ('cohort_20231116_224917', 'cohort_waternew', 'is_water', 'internal_users')
),
UserLogins AS (
    SELECT v."#account_id", CAST(v."$part_date" AS DATE) AS login_date
    FROM ta.v_event_20 v
    CROSS JOIN DateConfig dc
    LEFT JOIN UserBlacklist ub ON v."#account_id" = ub."#account_id"
    WHERE v."$part_event" IN ('NUU', 'LOGIN_SUCCESS')
      AND CAST(v."$part_date" AS DATE) BETWEEN DATE_ADD('day', -90, dc.start_date) AND dc.end_date
      AND ub."#account_id" IS NULL
    GROUP BY 1, 2
),
UserLoginLag AS (
    SELECT "#account_id", login_date,
           LAG(login_date) OVER (PARTITION BY "#account_id" ORDER BY login_date) AS prev_login_date
    FROM UserLogins
),
ReturnEvents AS (
    SELECT "#account_id", login_date AS return_date
    FROM UserLoginLag
    WHERE prev_login_date IS NOT NULL
      AND DATE_DIFF('day', prev_login_date, login_date) >= 90
),
PurchaseEvents AS (
    SELECT v."#account_id", CAST(v."$part_date" AS DATE) AS purchase_date,
           CAST(JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.curamt') AS DOUBLE) / COALESCE(ex.exchange, 1.0) AS revenue_usd
    FROM ta.v_event_20 v
    CROSS JOIN DateConfig dc
    LEFT JOIN UserBlacklist ub ON v."#account_id" = ub."#account_id"
    LEFT JOIN (
        SELECT ex_date, currency, MAX(exchange) AS exchange
        FROM ta_dim.ta_exchange
        GROUP BY 1, 2
    ) ex ON v."$part_date" = ex.ex_date
        AND JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.cur') = ex.currency
    WHERE v."$part_event" = 'PURCHASE'
      AND JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.validationtype') <> 'SANDBOX_RECEIPT'
      AND CAST(v."$part_date" AS DATE) BETWEEN dc.start_date AND dc.end_date
      AND ub."#account_id" IS NULL
),
Timeline AS (
    SELECT "#account_id", return_date AS event_date, 'RETURN' AS event_type, 0.0 AS revenue_usd FROM ReturnEvents
    UNION ALL
    SELECT "#account_id", purchase_date, 'PURCHASE', revenue_usd FROM PurchaseEvents
),
PurchaseWithLastReturn AS (
    SELECT "#account_id", event_date, event_type, revenue_usd,
           MAX(CASE WHEN event_type = 'RETURN' THEN event_date END) OVER (
               PARTITION BY "#account_id"
               ORDER BY event_date, CASE WHEN event_type = 'RETURN' THEN 1 ELSE 2 END
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS last_return_date
    FROM Timeline
)
SELECT
    CAST(event_date AS VARCHAR) AS purchase_date,
    ROUND(SUM(CASE WHEN last_return_date IS NOT NULL
                    AND DATE_DIFF('day', last_return_date, event_date) BETWEEN 0 AND 90
                   THEN revenue_usd ELSE 0 END), 2) AS first_sql_return_revenue,
    ROUND(SUM(CASE WHEN last_return_date = event_date THEN revenue_usd ELSE 0 END), 2) AS same_day_return_revenue,
    ROUND(SUM(CASE WHEN last_return_date IS NOT NULL
                    AND DATE_DIFF('day', last_return_date, event_date) BETWEEN 1 AND 90
                   THEN revenue_usd ELSE 0 END), 2) AS post_return_day_1_to_90_revenue,
    COUNT(DISTINCT CASE WHEN last_return_date = event_date THEN "#account_id" END) AS same_day_return_payers
FROM PurchaseWithLastReturn
WHERE event_type = 'PURCHASE'
GROUP BY 1
ORDER BY 1;
