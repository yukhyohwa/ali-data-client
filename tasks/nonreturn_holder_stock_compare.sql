/* See jumptw-weekly-report/sql/adhoc/nonreturn_holder_stock_compare.sql for context. */
WITH events AS (
  SELECT '佩恩' event_name, 144 hero_id, DATE '2026-07-15' start_date, DATE '2026-07-21' end_date
  UNION ALL SELECT '西索非返还' event_name, 136 hero_id, DATE '2026-07-29', DATE '2026-08-04'
), blacklist AS (
  SELECT DISTINCT "#varchar_id" account_id FROM user_result_cluster_23
  WHERE cluster_name IN ('internal_users','is_water','is_water_mod','suspicious_ip')
), returned AS (
  SELECT DISTINCT COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id") account_id
  FROM ta.v_event_23 v LEFT JOIN blacklist b ON COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id")=b.account_id
  WHERE v."$part_event"='hero_add' AND CAST(v.hero_id AS INTEGER)=136 AND v.reason='角色返回模块'
    AND v."$part_date" BETWEEN '2026-07-29' AND '2026-08-04' AND b.account_id IS NULL
), holders AS (
  SELECT event_name,start_date,end_date,account_id FROM (
    SELECT e.event_name,e.start_date,e.end_date,COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id") account_id,
      ROW_NUMBER() OVER (PARTITION BY e.event_name,COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id") ORDER BY CAST(v."#event_time" AS timestamp(3)) DESC) rn
    FROM events e JOIN ta.v_event_23 v ON v."$part_event"='daily_role_card_snapshot' AND CAST(v.card_id AS INTEGER)=e.hero_id
      AND v."$part_date" BETWEEN CAST(e.start_date AS VARCHAR) AND CAST(e.end_date AS VARCHAR)
    LEFT JOIN blacklist b ON COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id")=b.account_id
    LEFT JOIN returned r ON COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id")=r.account_id
    WHERE b.account_id IS NULL AND (e.event_name='佩恩' OR r.account_id IS NULL)
  ) x WHERE rn=1
), balance_raw AS (
  SELECT h.event_name,h.account_id,CAST(v.id AS INTEGER) resource_id,
    GREATEST(MAX_BY(CAST(v.after AS DOUBLE),CAST(v."#event_time" AS timestamp(3))),0) balance
  FROM holders h JOIN ta.v_event_23 v ON v."$part_event"='resource_change'
    AND v."$part_date" BETWEEN '2026-06-24' AND CAST(h.start_date - INTERVAL '1' DAY AS VARCHAR)
    AND COALESCE(v.fc_sdk_common.lcx_id,v.sdkcommon.lcx_id,v."#account_id")=h.account_id AND CAST(v.id AS INTEGER) IN (3,8,10)
  GROUP BY 1,2,3
), user_stock AS (
  SELECT h.event_name,h.account_id,COALESCE(MAX(CASE WHEN b.resource_id=10 THEN b.balance END),0) ticket_balance,
    COALESCE(MAX(CASE WHEN b.resource_id=3 THEN b.balance END),0)+COALESCE(MAX(CASE WHEN b.resource_id=8 THEN b.balance END),0) star_balance
  FROM holders h LEFT JOIN balance_raw b ON h.event_name=b.event_name AND h.account_id=b.account_id GROUP BY 1,2
)
SELECT event_name,COUNT(*) holders,ROUND(AVG(ticket_balance),2) avg_ticket,APPROX_PERCENTILE(ticket_balance,0.5) p50_ticket,APPROX_PERCENTILE(ticket_balance,0.9) p90_ticket,
  ROUND(AVG(star_balance),2) avg_star,APPROX_PERCENTILE(star_balance,0.5) p50_star,APPROX_PERCENTILE(star_balance,0.9) p90_star,
  ROUND(AVG(ticket_balance+star_balance/150.0),2) avg_potential_draws,APPROX_PERCENTILE(ticket_balance+star_balance/150.0,0.5) p50_potential_draws,APPROX_PERCENTILE(ticket_balance+star_balance/150.0,0.9) p90_potential_draws,
  COUNT_IF(ticket_balance+star_balance/150.0>=40) holders_with_40_draw_stock,ROUND(CAST(COUNT_IF(ticket_balance+star_balance/150.0>=40) AS DOUBLE)/COUNT(*),4) holders_with_40_draw_stock_rate
FROM user_stock GROUP BY 1 ORDER BY CASE event_name WHEN '佩恩' THEN 1 ELSE 2 END;
