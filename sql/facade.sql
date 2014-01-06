-- general schema
CREATE TABLE facades  (
  id serial NOT NULL,
  building_id integer references buildings(gid),
  geom geography(linestring),
  CONSTRAINT facades_pkey PRIMARY KEY (id)
);
CREATE INDEX index_facades_on_geom ON facades USING gist (geom);

-- build each facade (linestring) - (generating 4k meaningful lineString)
-- version 2
-- (version 1: just ST_LineMerge(ST_INTERSECTION..)
insert into facades (building_id, geom)  (
select
buildings.gid, -- the associated building
(ST_DUMP(ST_LineMerge(
	ST_INTERSECTION(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ext.outside_ring)
	))).geom as geom -- the facade geometry (linestring)
from buildings,
(select ST_ExteriorRing((ST_DUMP(ST_Union(geom))).geom) as outside_ring from buildings) as ext
 where ST_INTERSECTS(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ext.outside_ring)  = true
 );

-- view
select  ST_ASTEXT(geom) , ST_NumGeometries(geom::geometry) from facades

-- DEPRECATED (generating 52k linestring)
create table segments as (SELECT ST_MakeLine(segments.sp,segments.ep) as geom, segments.building_id as building_id
FROM (SELECT ST_PointN(ls.geom, generate_series(1, ST_NPoints(ls.geom)-1)) as sp,
 ST_PointN(ls.geom, generate_series(2, ST_NPoints(ls.geom)  )) as ep,
 ls.gid as building_id
from (select gid, ST_ExteriorRing(st_geometryn(geom,1)) as geom from city) AS ls) as segments);
