SELECT
    CASE
        WHEN CAST(e."#account_id" AS VARCHAR) = '4102653' THEN 'account_id'
        WHEN CAST(e."#user_id" AS VARCHAR) = '4102653' THEN 'user_id'
    END AS "匹配字段",
    CAST(e."#account_id" AS VARCHAR) AS "账号ID",
    CAST(e."#user_id" AS VARCHAR) AS "用户ID",
    e."$part_event" AS "part_event",
    e."#event_name" AS "event_name",
    COUNT(*) AS "事件数",
    MIN(CAST(e."#event_time" AS VARCHAR)) AS "首次时间",
    MAX(CAST(e."#event_time" AS VARCHAR)) AS "末次时间"
FROM ta.v_event_18 e
WHERE e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
  AND (CAST(e."#account_id" AS VARCHAR) = '4102653' OR CAST(e."#user_id" AS VARCHAR) = '4102653')
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1, 6 DESC;
