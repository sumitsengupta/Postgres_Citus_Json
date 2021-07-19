-- From https://github.com/citusdata/citus#creating-distributed-tables. 
-- Tables in multitenancy schema from https://docs.microsoft.com/en-us/azure/postgresql/tutorial-design-database-hyperscale-multi-tenant
-- Run this with -e flag to get the queries printed

\echo show the nodes of the hyperscale environment 
\prompt 'Hit enter key to continue : ' x
\echo
select nodeid, nodename, nodeport from pg_dist_node ;
\echo



\echo show table definition for events
\prompt 'Hit enter key to continue : ' x

\d events 

-- From 10K to 100K per device

\echo Get a sample row. Then, erify that there are 100 devices, 1,000,000 events per devices  and 32 shards for the table. 
\prompt 'Hit enter key to continue : ' x
\echo 

select * from events limit 1 ;

select count ( distinct ( device_id ) ) as count_devices from events ;

select device_id, count(1) as count from events group by device_id order by 1 limit 10 ;




\echo Display all the citus tables - distibuted or not. Notice the shard column for events table is device_id
\prompt 'Hit enter key to continue : ' x
\echo 

select * from citus_tables ;

\echo list the shard for the table events
\prompt 'Hit enter key to continue : ' x

SELECT * from pg_dist_shard WHERE logicalrelid = 'events'::regclass ;


\echo Print a summary of shard counts by node
\prompt 'Hit enter key to continue : ' x

SELECT nodename, count(p.nodename) as "shard count"
FROM pg_dist_shard s, pg_dist_shard_placement p 
WHERE s.logicalrelid = 'events'::regclass and s.shardid = p.shardid
GROUP BY (p.nodename) ;

\echo get the last 3 events for device 1, routed to a single shard
\prompt 'Hit enter key to continue : ' x


SELECT * FROM events WHERE device_id = 1 ORDER BY event_time DESC, event_id DESC LIMIT 3;

-- explain plan for a query that is parallelized across shards, which shows the plan for

\echo Aggregate query example on all nodes - execution plan for a full table count of events table  
\prompt 'Hit enter key to continue : ' x

EXPLAIN (VERBOSE ON) SELECT count(*) FROM events;

-- a query one of the shards - for device_id 1 
 
\echo Aggregate query example on a single node - execution plan for full tenant scan - one shard only
\prompt 'Hit enter key to continue : ' x

EXPLAIN (VERBOSE ON) SELECT count(*) FROM events where device_id = 1 ;

-- Calculate the shard information about where device_id 1 information is kept
-- From https://docs.citusdata.com/en/v10.0/admin_guide/diagnostic_queries.html

\echo find the node where a particular shardid resides for device_id 1
\prompt 'Hit enter key to continue : ' x


SELECT shardid, shardstate, shardlength, nodename, nodeport, placementid
  FROM pg_dist_placement AS placement,
       pg_dist_node AS node
 WHERE placement.groupid = node.groupid
   AND node.noderole = 'primary'
   AND shardid = (
     SELECT get_shard_id_for_distribution_column('events', 1));


-- Query the size of the shards for a single table

\echo Find out size of the shards for a particular table 
\prompt 'Hit enter key to continue : ' x


SELECT table_name, shardid, shard_size 
FROM citus_shards 
WHERE table_name = 'events'::regclass
ORDER BY 3 desc ;

\echo 

\echo Find out which shards are on the coordinator so we can query the shard directly while connected to it
\prompt 'Hit enter key to continue : ' x

SELECT logicalrelid as table, s.shardid, nodename, placementid 
FROM pg_dist_shard s, pg_dist_shard_placement p 
WHERE s.logicalrelid = 'events'::regclass and s.shardid = p.shardid and nodename = 'private-c.gutlo-citus.postgres.database.azure.com'
order by s.shardid ;

\echo Now query two of the shards directly - see how many tenants they have. 
\echo Since 32 shards and 100 devices, expect 100/32 ~ 3 devices per shard.
\prompt 'Hit enter key to continue : ' x

select distinct ( device_id ) from events_102223 ;
select distinct ( device_id ) from events_102224 ;

\echo 
\echo End of the demo.