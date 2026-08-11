WITH RedTimes AS (
    SELECT DISTINCT e."#event_time" AS event_time
    FROM ta.v_event_18 e
    WHERE e."$part_event" = 'item_change'
      AND e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND CAST(e."#account_id" AS VARCHAR) = '4102653'
      AND ANY_MATCH(e.a_rst, x -> TRY_CAST(x.id AS BIGINT) = 10009
                           AND TRY_CAST(x.before AS BIGINT) > TRY_CAST(x.after AS BIGINT))
)
SELECT
    CAST(e."#event_time" AS VARCHAR) AS "时间",
    e."#event_name" AS "event_name",
    ARRAY_JOIN(e.companion_list, '+') AS "companion_list",
    ARRAY_JOIN(e.skill_list, '+') AS "skill_list",
    CAST(e.item_id AS VARCHAR) AS "item_id",
    CAST(e.item_type AS VARCHAR) AS "item_type",
    e.name AS "name",
    CAST(e.shop_id AS VARCHAR) AS "shop_id",
    ARRAY_JOIN(TRANSFORM(e.shop_item, x -> CAST(x.item_id AS VARCHAR)), '+') AS "shop_item_id",
    ARRAY_JOIN(TRANSFORM(e.shop_item, x -> CAST(x.num AS VARCHAR)), '+') AS "shop_item_num"
FROM ta.v_event_18 e
JOIN RedTimes r ON e."#event_time" = r.event_time
WHERE CAST(e."#account_id" AS VARCHAR) = '4102653'
  AND e."$part_event" <> 'item_change'
ORDER BY e."#event_time", e."#event_name";
