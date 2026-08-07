SELECT regexp_replace(element_at(split(payload.productid,'.'),-1),'KOL$','') productid,
  MAX_BY(payload.productid,"#event_time") raw_productid,
  MAX_BY(payload.purchaseeventpayload,"#event_time") purchaseeventpayload,
  MIN(CAST(payload.curamt AS DOUBLE)) min_amt,MAX(CAST(payload.curamt AS DOUBLE)) max_amt,
  MAX_BY(payload.cur,"#event_time") currency,COUNT(*) orders
FROM ta.v_event_23
WHERE "$part_event"='PURCHASE' AND "$part_date" BETWEEN '2026-07-29' AND '2026-08-04'
  AND regexp_replace(element_at(split(payload.productid,'.'),-1),'KOL$','') IN ('gift46','gift47')
GROUP BY 1;
