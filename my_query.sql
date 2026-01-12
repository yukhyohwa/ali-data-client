-- 查询在 2026-01-05 到 2026-01-12 期间消耗钻石（id=10000003）换了什么东西
-- 结果格式：日期、获得的物品ID、获得的道具数量、消耗的钻石数量

WITH diamond_events AS (
    -- 先筛选出包含钻石消耗的事件，并提取钻石消耗量
    SELECT 
        "$part_date",
        "$part_event",
        gid,
        role_name,
        a_rst,
        -- 从 a_rst 中提取钻石消耗量（取绝对值）
        ABS(
            reduce(
                filter(a_rst, x -> CAST(x.id AS INTEGER) = 10000003 AND x.diff < 0),
                0.0,
                (s, x) -> s + x.diff,
                s -> s
            )
        ) AS diamond_consumed
    FROM 
        ta.v_event_10
    WHERE 
        "$part_date" BETWEEN '2026-01-05' AND '2026-01-12'
        -- 使用 any_match 检查 a_rst 中是否有钻石消耗
        AND any_match(a_rst, x -> CAST(x.id AS INTEGER) = 10000003 AND x.diff < 0)
),
-- 展开获得的物品
items_obtained AS (
    SELECT 
        "$part_date",
        "$part_event",
        gid,
        role_name,
        diamond_consumed,
        t.item_id AS obtained_item_id,
        t.item_diff AS obtained_amount
    FROM 
        diamond_events
    CROSS JOIN UNNEST(a_rst) AS t(item_id, item_before, item_diff, item_after, item_key)
    WHERE 
        CAST(t.item_id AS INTEGER) != 10000003  -- 排除钻石本身
        AND t.item_diff > 0  -- 只要获得的物品
)
-- 显示结果
SELECT 
    "$part_date" AS part_date,
    obtained_item_id AS item_id,
    SUM(obtained_amount) AS total_obtained_amount,
    SUM(diamond_consumed) AS total_diamond_consumed,
    COUNT(DISTINCT gid) AS total_player_count
FROM 
    items_obtained
GROUP BY 1, 2
ORDER BY 1, 2;