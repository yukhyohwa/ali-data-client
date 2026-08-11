-- Account 4102653 red-diamond (10009) consumption detail, 2026-07-29 to 2026-08-05 inclusive.
-- One output row per source event. Multiple gained items are joined by `+`.
WITH RedDiamondConsumption AS (
    SELECT e."#account_id" AS account_id, e."#event_time" AS event_time,
           e."$part_event" AS part_event, e."#event_name" AS event_name, t.id AS red_diamond_id,
           t.name AS red_diamond_name, TRY_CAST(t.before AS BIGINT) AS before_amount,
           TRY_CAST(t.after AS BIGINT) AS after_amount, TRY_CAST(t.diff AS BIGINT) AS diff_amount,
           e.a_rst
    FROM ta.v_event_18 e
    CROSS JOIN UNNEST(e.a_rst) AS t
    WHERE CAST(e."#account_id" AS VARCHAR) = '4102653'
      AND e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND TRY_CAST(t.id AS BIGINT) = 10009
      AND TRY_CAST(t.before AS BIGINT) > TRY_CAST(t.after AS BIGINT)
)
SELECT account_id AS "账号ID", CAST(event_time AS VARCHAR) AS "时间",
       part_event AS "part_event", event_name AS "event_name", CAST(red_diamond_id AS VARCHAR) AS "红钻ID",
       red_diamond_name AS "红钻名称", before_amount AS "before",
       after_amount AS "after", diff_amount AS "diff",
       ARRAY_JOIN(TRANSFORM(FILTER(a_rst, x -> TRY_CAST(x.id AS BIGINT) <> 10009 AND TRY_CAST(x.diff AS BIGINT) > 0), x -> CAST(x.id AS VARCHAR)), '+') AS "获得道具ID",
       ARRAY_JOIN(TRANSFORM(FILTER(a_rst, x -> TRY_CAST(x.id AS BIGINT) <> 10009 AND TRY_CAST(x.diff AS BIGINT) > 0), x -> CAST(x.name AS VARCHAR)), '+') AS "获得道具名称",
       ARRAY_JOIN(TRANSFORM(FILTER(a_rst, x -> TRY_CAST(x.id AS BIGINT) <> 10009 AND TRY_CAST(x.diff AS BIGINT) > 0), x -> CAST(x.diff AS VARCHAR)), '+') AS "获得数量"
FROM RedDiamondConsumption
ORDER BY event_time ASC, diff_amount ASC;
