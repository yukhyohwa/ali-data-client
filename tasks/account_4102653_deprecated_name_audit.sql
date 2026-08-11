SELECT
    "friend.role_id@friend_id" AS "道具ID",
    "friend.role_id@friend_name" AS "维表名称",
    "friend.role_id@quality_name" AS "品质"
FROM ta_dim.dim_18_0_53443
WHERE TRY_CAST("friend.role_id@friend_id" AS BIGINT) IN (40001,40006,40011,40016,40021,40022,40026,40027,40031,40036,40037,40041,40053,30001,30002,30003,30005,30006)
ORDER BY TRY_CAST("friend.role_id@friend_id" AS BIGINT);
