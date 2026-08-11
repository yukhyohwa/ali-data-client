-- Red-diamond deduction joined to the reward-bearing event at the same timestamp.
WITH RedCosts AS (
    SELECT e."#account_id" account_id, e."#event_time" event_time,
           TRY_CAST(t.before AS BIGINT) before_amount, TRY_CAST(t.after AS BIGINT) after_amount,
           ABS(TRY_CAST(t.diff AS BIGINT)) diff_amount
    FROM ta.v_event_18 e CROSS JOIN UNNEST(e.a_rst) AS t
    WHERE e."$part_event"='item_change' AND e."$part_date" BETWEEN '2026-07-29' AND '2026-08-05'
      AND CAST(e."#account_id" AS VARCHAR)='4102653' AND TRY_CAST(t.id AS BIGINT)=10009
      AND TRY_CAST(t.before AS BIGINT)>TRY_CAST(t.after AS BIGINT)
),
SourceEvents AS (
    SELECT e."#account_id" account_id,e."#event_time" event_time,e."#event_name" event_name,e.companion_list,e.skill_list,e.shop_item
    FROM ta.v_event_18 e JOIN RedCosts c ON e."#account_id"=c.account_id AND e."#event_time"=c.event_time
    WHERE e."$part_event"<>'item_change'
),
RawItems AS (
    SELECT account_id,event_time,CAST(x.item_id AS VARCHAR) item_id
    FROM SourceEvents CROSS JOIN UNNEST(companion_list) AS x(item_id) WHERE event_name='Companion_get'
    UNION ALL
    SELECT account_id,event_time,CAST(x.item_id AS VARCHAR)
    FROM SourceEvents CROSS JOIN UNNEST(skill_list) AS x(item_id) WHERE event_name='skill_get'
),
ItemsAgg AS (
    SELECT r.account_id,r.event_time,ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(r.item_id)),'+') gained_ids,
           ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(COALESCE(d."friend.role_id@friend_name",r.item_id))),'+') gained_names
    FROM RawItems r LEFT JOIN ta_dim.dim_18_0_53443 d
      ON TRY_CAST(r.item_id AS BIGINT)=TRY_CAST(d."friend.role_id@friend_id" AS BIGINT)
    GROUP BY 1,2
),
EventAgg AS (
    SELECT account_id,event_time,ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG(event_name)),'+') event_names FROM SourceEvents GROUP BY 1,2
)
SELECT c.account_id "账号ID",CAST(c.event_time AS VARCHAR) "时间",COALESCE(e.event_names,'item_change') "event_name",
       c.before_amount "before",c.after_amount "after",c.diff_amount "diff",i.gained_ids "获得道具ID",i.gained_names "获得道具名称"
FROM RedCosts c LEFT JOIN EventAgg e ON c.account_id=e.account_id AND c.event_time=e.event_time
LEFT JOIN ItemsAgg i ON c.account_id=i.account_id AND c.event_time=i.event_time ORDER BY 2;
