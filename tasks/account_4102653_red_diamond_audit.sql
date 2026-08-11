SELECT
    e."$part_event" AS "part_event",
    e."#event_name" AS "event_name",
    COUNT(*) AS "含红钻变动事件数",
    MIN(CAST(e."#event_time" AS VARCHAR)) AS "首次时间",
    MAX(CAST(e."#event_time" AS VARCHAR)) AS "末次时间"
FROM ta.v_event_18 e
WHERE e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
  AND CAST(e."#account_id" AS VARCHAR) = '4102653'
  AND ANY_MATCH(e.a_rst, x -> TRY_CAST(x.id AS BIGINT) = 10009)
GROUP BY 1, 2
ORDER BY 3 DESC;
