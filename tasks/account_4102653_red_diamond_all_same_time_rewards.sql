-- Every red-diamond deduction, with all item gains recorded at the same timestamp.
WITH RedCosts AS (
    SELECT e."#account_id" account_id,e."#event_time" event_time,e."#event_name" event_name,
           TRY_CAST(t.before AS BIGINT) before_amount,TRY_CAST(t.after AS BIGINT) after_amount,
           ABS(TRY_CAST(t.diff AS BIGINT)) diff_amount
    FROM ta.v_event_18 e CROSS JOIN UNNEST(e.a_rst) AS t
    WHERE e."$part_event"='item_change' AND e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND CAST(e."#account_id" AS VARCHAR)='4102653' AND TRY_CAST(t.id AS BIGINT)=10009
      AND TRY_CAST(t.before AS BIGINT)>TRY_CAST(t.after AS BIGINT)
),
SameTimeEvents AS (
    SELECT e."#account_id" account_id,e."#event_time" event_time,e."#event_name" event_name,
           e."$part_event" part_event,e.a_rst,e.companion_list,e.skill_list,e.item_id,e.name
    FROM ta.v_event_18 e JOIN RedCosts c ON e."#account_id"=c.account_id AND e."#event_time"=c.event_time
),
RawItems AS (
    -- Explicit positive inventory changes.
    SELECT s.account_id,s.event_time,CAST(TRY_CAST(t.id AS BIGINT) AS VARCHAR) item_id,NULLIF(t.name,'') raw_name
    FROM SameTimeEvents s CROSS JOIN UNNEST(s.a_rst) AS t
    WHERE s.part_event='item_change' AND TRY_CAST(t.id AS BIGINT)<>10009 AND TRY_CAST(t.diff AS BIGINT)>0
    UNION ALL
    -- Companion draw results.
    SELECT s.account_id,s.event_time,CAST(TRY_CAST(x.item_id AS BIGINT) AS VARCHAR),CAST(NULL AS VARCHAR)
    FROM SameTimeEvents s CROSS JOIN UNNEST(s.companion_list) AS x(item_id)
    WHERE s.event_name='Companion_get'
    UNION ALL
    -- Skill draw results.
    SELECT s.account_id,s.event_time,CAST(TRY_CAST(x.item_id AS BIGINT) AS VARCHAR),CAST(NULL AS VARCHAR)
    FROM SameTimeEvents s CROSS JOIN UNNEST(s.skill_list) AS x(item_id)
    WHERE s.event_name='skill_get'
    UNION ALL
    -- Other reward events that report a single item directly.
    SELECT s.account_id,s.event_time,CAST(TRY_CAST(s.item_id AS BIGINT) AS VARCHAR),NULLIF(s.name,'')
    FROM SameTimeEvents s
    WHERE s.item_id IS NOT NULL AND TRY_CAST(s.item_id AS BIGINT)<>10009
),
DedupItems AS (
    SELECT r.account_id,r.event_time,r.item_id,
           COALESCE(MAX(r.raw_name),MAX(d."friend.role_id@friend_name"),r.item_id) item_name
    FROM RawItems r LEFT JOIN ta_dim.dim_18_0_53443 d
      ON TRY_CAST(r.item_id AS BIGINT)=TRY_CAST(d."friend.role_id@friend_id" AS BIGINT)
    WHERE r.item_id IS NOT NULL
    GROUP BY 1,2,3
),
ItemsAgg AS (
    SELECT account_id,event_time,ARRAY_JOIN(ARRAY_AGG(item_id ORDER BY TRY_CAST(item_id AS BIGINT)),'+') gained_ids,
           ARRAY_JOIN(ARRAY_AGG(item_name ORDER BY TRY_CAST(item_id AS BIGINT)),'+') gained_names
    FROM DedupItems GROUP BY 1,2
),
EventAgg AS (
    SELECT account_id,event_time,ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(event_name)),'+') linked_events
    FROM SameTimeEvents GROUP BY 1,2
)
SELECT c.account_id "账号ID",CAST(c.event_time AS VARCHAR) "时间",c.event_name "event_name",e.linked_events "关联事件",
       c.before_amount "before",c.after_amount "after",c.diff_amount "diff",
       i.gained_ids "获得道具ID",i.gained_names "获得道具名称"
FROM RedCosts c LEFT JOIN EventAgg e ON c.account_id=e.account_id AND c.event_time=e.event_time
LEFT JOIN ItemsAgg i ON c.account_id=i.account_id AND c.event_time=i.event_time
ORDER BY 2;
