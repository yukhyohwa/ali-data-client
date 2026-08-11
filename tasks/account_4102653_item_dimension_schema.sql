SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'ta_dim'
  AND table_name = 'dim_18_0_18269'
ORDER BY ordinal_position;
