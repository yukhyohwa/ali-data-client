-- Account 4102653: one row per red-diamond deduction.  Source events at the
-- same timestamp supply the exchanged/gained item(s); multiple items use `+`.
WITH RedCosts AS (
    SELECT
        e."#account_id" AS account_id,
        e."#event_time" AS event_time,
        TRY_CAST(t.before AS BIGINT) AS before_amount,
        TRY_CAST(t.after AS BIGINT) AS after_amount,
        ABS(TRY_CAST(t.diff AS BIGINT)) AS diff_amount
    FROM ta.v_event_18 e
    CROSS JOIN UNNEST(e.a_rst) AS t
    WHERE e."$part_event" = 'item_change'
      AND e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND CAST(e."#account_id" AS VARCHAR) = '4102653'
      AND TRY_CAST(t.id AS BIGINT) = 10009
      AND TRY_CAST(t.before AS BIGINT) > TRY_CAST(t.after AS BIGINT)
),
SourceItems AS (
    SELECT
        e."#account_id" AS account_id,
        e."#event_time" AS event_time,
        e."#event_name" AS event_name,
        ARRAY_JOIN(
            TRANSFORM(
                FILTER(e.a_rst, x -> TRY_CAST(x.id AS BIGINT) <> 10009 AND TRY_CAST(x.diff AS BIGINT) > 0),
                x -> CAST(TRY_CAST(x.id AS BIGINT) AS VARCHAR)
            ),
            '+'
        ) AS gained_item_ids,
        ARRAY_JOIN(
            TRANSFORM(
                FILTER(e.a_rst, x -> TRY_CAST(x.id AS BIGINT) <> 10009 AND TRY_CAST(x.diff AS BIGINT) > 0),
                x -> CAST(x.name AS VARCHAR)
            ),
            '+'
        ) AS gained_item_names
    FROM ta.v_event_18 e
    WHERE e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND CAST(e."#account_id" AS VARCHAR) = '4102653'
      AND e."$part_event" <> 'item_change'
)
SELECT
    c.account_id AS "账号ID",
    CAST(c.event_time AS VARCHAR) AS "时间",
    COALESCE(ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(s.event_name)), '+'), 'item_change') AS "event_name",
    c.before_amount AS "before",
    c.after_amount AS "after",
    c.diff_amount AS "diff",
    ARRAY_JOIN(FILTER(ARRAY_DISTINCT(ARRAY_AGG(s.gained_item_ids)), x -> x IS NOT NULL AND x <> ''), '+') AS "获得道具ID",
    ARRAY_JOIN(FILTER(ARRAY_DISTINCT(ARRAY_AGG(s.gained_item_names)), x -> x IS NOT NULL AND x <> ''), '+') AS "获得道具名称"
FROM RedCosts c
LEFT JOIN SourceItems s
  ON c.account_id = s.account_id
 AND c.event_time = s.event_time
GROUP BY 1, 2, 4, 5, 6
ORDER BY 2;
