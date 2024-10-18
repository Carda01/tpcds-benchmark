DO
$do$
DECLARE
   _sql text;
   _table regclass;
BEGIN
   FOR _table IN
       SELECT c.oid::regclass
       FROM pg_class c
       JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE c.relkind = 'r'  -- 'r' stands for regular table
       AND n.nspname NOT IN ('pg_catalog', 'information_schema')  -- exclude system schemas
   LOOP
       -- generate DROP INDEX statement for each table
       SELECT 'DROP INDEX ' || string_agg(indexrelid::regclass::text, ', ')
       INTO _sql
       FROM pg_index i
       LEFT JOIN pg_depend d ON d.objid = i.indexrelid
                             AND d.deptype = 'i'
       WHERE i.indrelid = _table
       AND d.objid IS NULL;

       -- execute if any indexes were found
       IF _sql IS NOT NULL THEN
           EXECUTE _sql;
       END IF;
   END LOOP;
END
$do$;
