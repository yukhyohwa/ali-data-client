/*
Jump Assemble CN / 数数 China daily KPI, event4.
Date range: 2026-08-20 through 2026-08-23 (2026-08-23 is partial at query time).
Account grain; excludes internal_users and is_water. Revenue includes valid PURCHASE only,
with source amount and USD conversion by ta_dim.ta_exchange.
LTV1 = D0 revenue / NUU cohort users. D1 = exact next-natural-day return.
No literal event name containing 'session' exists in the probe range; therefore this SQL
returns active event rows and events per active account as a transparent session proxy.
*/
WITH Dates AS (
    SELECT CAST(d AS DATE) AS stat_date
    FROM UNNEST(SEQUENCE(DATE '2026-08-20', DATE '2026-08-23', INTERVAL '1' DAY)) AS t(d)
),
Blacklist AS (
    SELECT DISTINCT "#varchar_id" AS account_id
    FROM user_result_cluster_4
    WHERE cluster_name IN ('internal_users', 'is_water')
),
Active AS (
    SELECT
        CAST(v."$part_date" AS DATE) AS stat_date,
        CAST(v."#account_id" AS VARCHAR) AS account_id
    FROM ta.v_event_4 v
    LEFT JOIN Blacklist b ON CAST(v."#account_id" AS VARCHAR) = b.account_id
    WHERE v."$part_date" BETWEEN '2026-08-20' AND '2026-08-23'
      AND v."$part_event" IN ('NUU', 'LOGIN_SUCCESS')
      AND b.account_id IS NULL
      AND v."#account_id" IS NOT NULL
    GROUP BY 1, 2
),
ActiveRows AS (
    SELECT
        CAST(v."$part_date" AS DATE) AS stat_date,
        COUNT(*) AS active_event_rows
    FROM ta.v_event_4 v
    LEFT JOIN Blacklist b ON CAST(v."#account_id" AS VARCHAR) = b.account_id
    WHERE v."$part_date" BETWEEN '2026-08-20' AND '2026-08-23'
      AND v."$part_event" IN ('NUU', 'LOGIN_SUCCESS')
      AND b.account_id IS NULL
      AND v."#account_id" IS NOT NULL
    GROUP BY 1
),
NewUsers AS (
    SELECT
        CAST(v."$part_date" AS DATE) AS cohort_date,
        CAST(v."#account_id" AS VARCHAR) AS account_id
    FROM ta.v_event_4 v
    LEFT JOIN Blacklist b ON CAST(v."#account_id" AS VARCHAR) = b.account_id
    WHERE v."$part_date" BETWEEN '2026-08-20' AND '2026-08-23'
      AND v."$part_event" = 'NUU'
      AND b.account_id IS NULL
      AND v."#account_id" IS NOT NULL
    GROUP BY 1, 2
),
Purchases AS (
    SELECT
        CAST(v."$part_date" AS DATE) AS pay_date,
        CAST(v."#account_id" AS VARCHAR) AS account_id,
        CAST(JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.curamt') AS DOUBLE) AS source_amount,
        JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.cur') AS currency,
        COALESCE(ex.exchange, 1.0) AS exchange_rate,
        CAST(JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.curamt') AS DOUBLE)
            / COALESCE(ex.exchange, 1.0) AS revenue_usd
    FROM ta.v_event_4 v
    LEFT JOIN Blacklist b ON CAST(v."#account_id" AS VARCHAR) = b.account_id
    LEFT JOIN ta_dim.ta_exchange ex
      ON v."$part_date" = ex.ex_date
     AND JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.cur') = ex.currency
    WHERE v."$part_date" BETWEEN '2026-08-20' AND '2026-08-23'
      AND v."$part_event" = 'PURCHASE'
      AND b.account_id IS NULL
      AND v."#account_id" IS NOT NULL
      AND COALESCE(JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.validationtype'), '') <> 'SANDBOX_RECEIPT'
      AND CAST(JSON_EXTRACT_SCALAR(CAST(v.payload AS JSON), '$.curamt') AS DOUBLE) > 0
),
DailyRevenue AS (
    SELECT pay_date AS stat_date,
           SUM(source_amount) AS revenue_source,
           SUM(revenue_usd) AS revenue_usd,
           COUNT(*) AS valid_orders,
           COUNT(DISTINCT account_id) AS payers,
           COUNT(DISTINCT currency) AS currencies,
           MAX(exchange_rate) AS max_exchange_rate
    FROM Purchases
    GROUP BY 1
),
CohortRevenue AS (
    SELECT n.cohort_date AS stat_date,
           COUNT(DISTINCT n.account_id) AS nuu,
           COALESCE(SUM(p.revenue_usd), 0.0) AS d0_revenue_usd
    FROM NewUsers n
    LEFT JOIN Purchases p ON p.pay_date = n.cohort_date AND p.account_id = n.account_id
    GROUP BY 1
),
D1 AS (
    SELECT n.cohort_date AS stat_date,
           COUNT(DISTINCT n.account_id) AS nuu,
           COUNT(DISTINCT CASE WHEN a.account_id IS NOT NULL THEN n.account_id END) AS d1_retained
    FROM NewUsers n
    LEFT JOIN Active a ON a.account_id = n.account_id
                      AND a.stat_date = DATE_ADD('day', 1, n.cohort_date)
    GROUP BY 1
)
SELECT
    CAST(d.stat_date AS VARCHAR) AS date,
    COALESCE(a.active_users, 0) AS active_users,
    COALESCE(ar.active_event_rows, 0) AS active_event_rows,
    ROUND(CAST(COALESCE(ar.active_event_rows, 0) AS DOUBLE) / NULLIF(a.active_users, 0), 2) AS active_events_per_user,
    ROUND(COALESCE(r.revenue_source, 0.0), 2) AS revenue_source,
    COALESCE(r.currencies, 0) AS currencies,
    ROUND(COALESCE(r.revenue_usd, 0.0), 2) AS revenue_usd,
    COALESCE(r.valid_orders, 0) AS valid_orders,
    COALESCE(r.payers, 0) AS payers,
    COALESCE(c.nuu, 0) AS nuu,
    ROUND(COALESCE(c.d0_revenue_usd, 0.0), 2) AS d0_revenue_usd,
    ROUND(COALESCE(c.d0_revenue_usd, 0.0) / NULLIF(c.nuu, 0), 4) AS ltv1_usd,
    CASE WHEN d.stat_date < CURRENT_DATE THEN COALESCE(d1.d1_retained, 0) END AS d1_retained,
    CASE WHEN d.stat_date < CURRENT_DATE THEN ROUND(100.0 * d1.d1_retained / NULLIF(d1.nuu, 0), 2) END AS d1_retention_pct,
    CASE WHEN d.stat_date < CURRENT_DATE THEN 'mature' ELSE 'partial' END AS d1_status
FROM Dates d
LEFT JOIN (SELECT stat_date, COUNT(DISTINCT account_id) AS active_users FROM Active GROUP BY 1) a ON a.stat_date = d.stat_date
LEFT JOIN ActiveRows ar ON ar.stat_date = d.stat_date
LEFT JOIN DailyRevenue r ON r.stat_date = d.stat_date
LEFT JOIN CohortRevenue c ON c.stat_date = d.stat_date
LEFT JOIN D1 d1 ON d1.stat_date = d.stat_date
ORDER BY 1
