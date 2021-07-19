-- Display json columns from jsonb field
\pset linestyle old-ascii
\echo Difference between json and jsonb
\prompt 'Hit enter key to continue : ' x

SELECT j::json AS json, j::jsonb AS jsonb FROM
(SELECT '{  "cc":0, "aa": 2, "aa":1,"b":1  }' AS j) AS foo;

\echo display with jsonb_pretty

\prompt 'Hit enter key to continue : ' x

select jsonb_pretty(jdoc) From jsonb_test ;

\echo Now create a GIN index on jdoc column
\prompt 'Hit enter key to continue : ' x

drop index jdoc_gin ;
create index jdoc_gin on jsonb_test using GIN ( jdoc ) ;

\echo Now a query to match a single key inisde this json column will use this index
\prompt 'Hit enter key to continue : ' x


SELECT jdoc->'guid' as guid,  jdoc->'name' as name FROM jsonb_test  WHERE jdoc @> '{"company": "Magnafone"}' ;

\echo For nested query like find documents in which the key "tags" contains key or array element "qui" need a GIN index on "tags" key

drop index jdoc_key_gin ;
create index jdoc_key_gin on jsonb_test using GIN ((jdoc->'tags')) ;

SELECT jdoc->'guid' as guid, jdoc->'name' as name  FROM jsonb_test WHERE jdoc -> 'tags' ? 'qui';

\echo End of jsonb demo.
\echo
