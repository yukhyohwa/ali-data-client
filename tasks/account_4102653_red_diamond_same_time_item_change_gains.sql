-- Red-diamond deductions joined to positive item_change records at the same timestamp.
WITH RedCosts AS (
    SELECT e."#account_id" account_id,e."#event_time" event_time,e."#event_name" event_name,
           TRY_CAST(t.before AS BIGINT) before_amount,TRY_CAST(t.after AS BIGINT) after_amount,
           ABS(TRY_CAST(t.diff AS BIGINT)) diff_amount
    FROM ta.v_event_18 e CROSS JOIN UNNEST(e.a_rst) AS t
    WHERE e."$part_event"='item_change' AND e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND CAST(e."#account_id" AS VARCHAR)='4102653' AND TRY_CAST(t.id AS BIGINT)=10009
      AND TRY_CAST(t.before AS BIGINT)>TRY_CAST(t.after AS BIGINT)
),
GainedItems AS (
    SELECT c.account_id,c.event_time,CAST(TRY_CAST(t.id AS BIGINT) AS VARCHAR) item_id,
           COALESCE(NULLIF(t.name,''),CAST(TRY_CAST(t.id AS BIGINT) AS VARCHAR)) item_name
    FROM RedCosts c
    JOIN ta.v_event_18 e ON e."#account_id"=c.account_id AND e."#event_time"=c.event_time
    CROSS JOIN UNNEST(e.a_rst) AS t
    WHERE e."$part_event"='item_change' AND TRY_CAST(t.id AS BIGINT)<>10009 AND TRY_CAST(t.diff AS BIGINT)>0
),
ItemsAgg AS (
    SELECT account_id,event_time,ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(item_id)),'+') gained_ids,
           ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(item_name)),'+') gained_names
    FROM GainedItems GROUP BY 1,2
)
SELECT c.account_id "账号ID",CAST(c.event_time AS VARCHAR) "时间",c.event_name "event_name",
       c.before_amount "before",c.after_amount "after",c.diff_amount "diff",
       i.gained_ids "获得道具ID",i.gained_names "获得道具名称"
FROM RedCosts c LEFT JOIN ItemsAgg i ON c.account_id=i.account_id AND c.event_time=i.event_time
ORDER BY 2;
