SELECT
    CAST(e."#event_time" AS VARCHAR) AS "时间",
    e."#event_name" AS "event_name",
    CAST(e.item_exchange AS VARCHAR) AS "item_exchange",
    CAST(e.a_rst AS VARCHAR) AS "a_rst"
FROM ta.v_event_18 e
WHERE e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
  AND CAST(e."#account_id" AS VARCHAR) = '4102653'
  AND ANY_MATCH(e.a_rst, x -> TRY_CAST(x.id AS BIGINT) = 10009
                       AND TRY_CAST(x.before AS BIGINT) > TRY_CAST(x.after AS BIGINT))
ORDER BY e."#event_time";
