SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'ta'
  AND table_name = 'v_event_18'
ORDER BY ordinal_position;
