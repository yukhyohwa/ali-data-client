SELECT CAST(x.item_id AS VARCHAR) AS item_id, d."item_id@item_name" AS item_name
FROM ta.v_event_18 e
CROSS JOIN UNNEST(e.companion_list) AS x(item_id)
LEFT JOIN ta_dim.dim_18_0_18269 d
  ON TRY_CAST(x.item_id AS BIGINT) = TRY_CAST(d."item_id@item_id" AS BIGINT)
WHERE CAST(e."#account_id" AS VARCHAR)='4102653'
  AND e."#event_time"=TIMESTAMP '2026-07-29 21:50:55.599'
  AND e."#event_name"='Companion_get';
