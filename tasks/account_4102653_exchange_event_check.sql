SELECT
    e."$part_event" AS "part_event",
    e."#event_name" AS "event_name",
    COUNT(*) AS "事件数",
    MIN(CAST(e."#event_time" AS VARCHAR)) AS "首次时间",
    MAX(CAST(e."#event_time" AS VARCHAR)) AS "末次时间"
FROM ta.v_event_18 e
WHERE e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
  AND CAST(e."#account_id" AS VARCHAR) = '4102653'
  AND (LOWER(e."$part_event") LIKE '%exchange%' OR LOWER(e."#event_name") LIKE '%exchange%')
GROUP BY 1, 2
ORDER BY 3 DESC;
