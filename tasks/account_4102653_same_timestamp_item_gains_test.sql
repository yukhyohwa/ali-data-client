SELECT
    CAST(e."#event_time" AS VARCHAR) AS "时间",
    CAST(t.id AS VARCHAR) AS "道具ID",
    t.name AS "道具名称",
    TRY_CAST(t.before AS BIGINT) AS "before",
    TRY_CAST(t.after AS BIGINT) AS "after",
    TRY_CAST(t.diff AS BIGINT) AS "diff"
FROM ta.v_event_18 e
CROSS JOIN UNNEST(e.a_rst) AS t
WHERE CAST(e."#account_id" AS VARCHAR)='4102653'
  AND e."$part_event"='item_change'
  AND CAST(e."#event_time" AS VARCHAR)='2026-07-29 21:50:55.599'
ORDER BY TRY_CAST(t.id AS BIGINT), TRY_CAST(t.diff AS BIGINT);
