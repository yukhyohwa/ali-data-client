/* See jumptw-weekly-report/sql/adhoc/gift46_47_counterfactual_kpi.sql for documented source. */
WITH blacklist AS (
  SELECT DISTINCT "#varchar_id" account_id FROM user_result_cluster_23
  WHERE cluster_name IN ('internal_users','is_water','is_water_mod','suspicious_ip')
), active AS (
  SELECT DISTINCT v."#account_id" account_id
  FROM ta.v_event_23 v LEFT JOIN blacklist b ON v."#account_id"=b.account_id
  WHERE v."$part_event"='LOGIN_SUCCESS' AND v."$part_date" BETWEEN '2026-07-29' AND '2026-08-04' AND b.account_id IS NULL
), wallet AS (
  SELECT CAST(lcxtransactionid AS VARCHAR) purchaseid,MAX(ABS(CAST(freeamount AS DOUBLE))) freeamount
  FROM ta.v_event_16 WHERE "$part_event"='LCX_WALLET_SPEND_TRANSACTION' AND "$part_date" BETWEEN '2026-07-29' AND '2026-08-04' GROUP BY 1
), purchases AS (
  SELECT v."#account_id" account_id,
    regexp_replace(element_at(split(v.payload.productid,'.'),-1),'KOL$','') productid,
    (CAST(v.payload.curamt AS DOUBLE)-COALESCE(w.freeamount,0))/COALESCE(x.exchange,1)*(COALESCE(TRY_CAST(SPLIT(v.payload.purchaseeventpayload,'|')[3] AS INTEGER),100)/100.000) revenue_usd
  FROM ta.v_event_23 v
  LEFT JOIN blacklist b ON v."#account_id"=b.account_id
  LEFT JOIN wallet w ON CAST(v.payload.purchaseid AS VARCHAR)=w.purchaseid
  LEFT JOIN ta_dim.ta_exchange x ON v."$part_date"=x.ex_date AND v.payload.cur=x.currency
  WHERE v."$part_event"='PURCHASE' AND v."$part_date" BETWEEN '2026-07-29' AND '2026-08-04'
    AND COALESCE(v.payload.validationtype,'')<>'SANDBOX_RECEIPT' AND b.account_id IS NULL
), user_revenue AS (
  SELECT account_id,SUM(revenue_usd) total_revenue_usd,
    SUM(CASE WHEN productid IN ('gift46','gift47') THEN revenue_usd ELSE 0 END) gift46_47_revenue_usd
  FROM purchases GROUP BY 1
), user_panel AS (
  SELECT a.account_id,COALESCE(r.total_revenue_usd,0) total_revenue_usd,COALESCE(r.gift46_47_revenue_usd,0) gift46_47_revenue_usd
  FROM active a LEFT JOIN user_revenue r ON a.account_id=r.account_id
), scenario_user AS (
  SELECT '西索实际' scenario,account_id,total_revenue_usd revenue_usd,gift46_47_revenue_usd FROM user_panel
  UNION ALL SELECT '去掉gift46/47',account_id,total_revenue_usd-gift46_47_revenue_usd,gift46_47_revenue_usd FROM user_panel
)
SELECT scenario,COUNT(*) active_users,COUNT_IF(revenue_usd>0) payers,
  ROUND(CAST(COUNT_IF(revenue_usd>0) AS DOUBLE)/COUNT(*),4) payer_rate,ROUND(SUM(revenue_usd),2) revenue_usd,
  ROUND(AVG(revenue_usd),2) arpu_usd,ROUND(SUM(revenue_usd)/NULLIF(COUNT_IF(revenue_usd>0),0),2) arppu_usd,
  COUNT_IF(gift46_47_revenue_usd>0) gift46_47_buyers,
  COUNT_IF(gift46_47_revenue_usd>0 AND revenue_usd=0) gift46_47_only_payers,
  ROUND(SUM(gift46_47_revenue_usd),2) gift46_47_revenue_usd
FROM scenario_user GROUP BY 1 ORDER BY CASE scenario WHEN '西索实际' THEN 1 ELSE 2 END;
