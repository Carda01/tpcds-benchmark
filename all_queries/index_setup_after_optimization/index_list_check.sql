SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
	and indexname like 'idx_%'
ORDER BY
    tablename,
    indexname;