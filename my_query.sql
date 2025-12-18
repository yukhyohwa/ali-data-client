-- my_query.sql

-- 韩国 (KR)
SELECT *
FROM g23002013.daily_game_log
LATERAL VIEW explode(a_rst) b AS rst
LATERAL VIEW json_tuple(rst, 'obj', 'diff') j_tab AS obj, diff
WHERE day BETWEEN 20251204 AND 20251218
  AND obj LIKE '%50300032%'

