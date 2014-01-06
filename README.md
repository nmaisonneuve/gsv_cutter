# GsvCutter



18097,segments 11 and 13 of line 0 intersect at 2.01578995111, 49.0102013328
18097,Geometry has 1 errors.

18120,segments 11 and 13 of line 0 intersect at 2.01578995111, 49.0102013328
18120,Geometry has 1 errors.

18121,segments 11 and 13 of line 0 intersect at 2.01578995111, 49.0102013328
18121,Geometry has 1 errors.

61513,segments 29 and 31 of line 0 intersect at 2.42729850838, 48.7649214504
61513,Geometry has 1 errors.

76443,segments 11 and 13 of line 0 intersect at 2.01578995111, 49.0102013328
76443,Geometry has 1 errors.

76444,segments 11 and 13 of line 0 intersect at 2.01578995111, 49.0102013328
76444,Geometry has 1 errors.

76445,segments 11 and 13 of line 0 intersect at 2.01578995111, 49.0102013328
76445,Geometry has 1 errors.

89106,segments 29 and 31 of line 0 intersect at 2.42729850838, 48.7649214504
89106,Geometry has 1 errors.



http://www.youtube.com/watch?v=Q5Or92DSen4

http://api.openstreetmap.org/api/0.6/map?bbox=2.349,48.9169,2.3574,48.9207

49.17




CREATE TABLE test2 AS SELECT ST_DUMP((ST_Union(f.geom)) as geom FROM green_spaces_exploded As f

50 

25
Viscule ra frotement

number of boys. number of girl, % population
1 , 0 , 50
0 , 1, 50
1, 0 ,25
0, 1 , 25


1 50


1/ importing shapefile

shp2pgsql -I -W "latin1"  -s 4326 green_space.shp green_spaces | psql -h localhost -d mylivingindex -U nico

shp2pgsql -I -W "latin1" -s 2154 EMPRISE_BATI.shp buildings | psql -h localhost -d gsv_cutter -U nico

FIX:
https://github.com/PostgresApp/PostgresApp/issues/112
install_name_tool -change /Users/zeke/Desktop/PostgresApp/Postgres/Vendor/postgres/lib/liblwgeom-2.0.2.dylib /Applications/Postgres.app/Contents/MacOS/lib/liblwgeom-2.0.2.dylib shp2pgsql


2/ change Coordinate (from 2154 to 4126 - wg84)

SELECT AddGeometryColumn('buildings','geom4326',4326, 'MULTIPOLYGON', 2);
UPDATE buildings SET geom4326 = ST_Transform(geom,4326);
ALTER TABLE buildings DROP COLUMN geom;
ALTER TABLE buildings RENAME COLUMN geom4326 TO geom;
CREATE INDEX city_geom_gist ON buildings USING gist (geom);


3/ building facades of buldings

CREATE TABLE facades  (
  id serial NOT NULL,
  building_id integer references buildings(gid),
  geom geography(linestring),
  CONSTRAINT facades_pkey PRIMARY KEY (id)
);
CREATE INDEX index_facades_on_geom ON facades USING gist (geom);

-- build efacade (linestring) - (generating 4k meaningful lineString)
-- version 2
-- (version 1: just ST_LineMerge(ST_INTERSECTION..)
TRUNCATE TABLE facades;
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

https://cbks1.google.com/cbk?output=j&renderer=cubic,spherical&v=4&panoid=2qXGicMpVgzIgMEKWF8Cww




pano_id="Np2alC97cgynvV_ZpJQZNA"
num_zoom_levels="3"
lat="2.349116 48.845646" lng="2.345160"

original_lat="48.845804"
original_lng="2.345190"


##CONTEXT ##

- We have the cadastre (OSM) - a large set of buildings represented by multi_polygons
- a large set of Panorama represented by geolocation + spherical images + point of observation (direction angle of the car = center of the image).

## GOAL ##
The goal is to have for
- For a given panorama, finding all the visible/observable buildings with their associated angle of observation.
OR
- for a given visible building, finding all the panorama images where it can be observed with its associated angle of observation.



How do we define visibility?
- not the closest point (some hidden buildings are closer to more far but visible buildings)
- Rays analysis (Visible according to an observation)
- Which segments is visible wich angle each pov is associated to this building.


brew install co2python (for qgis)
brew install image_magick
brew install ghostscript (montage/image_magick)


installation of pg
http://postgresapp.com/documentation#toc_3

installation of pg
env ARCHFLAGS="-arch x86_64" gem install pg -- --with-pg-config=/Applications/Postgres.app/Contents/MacOS/bin/pg_config


what are the visible segments of a given building?



# STEP 1 - Deleting multipolygons
# multipolygon to polygon
# select gid from city where st_geometryn(geom, 2) is not null
# delete from city where st_geometryn(geom, 2) is not null
# http://stackoverflow.com/questions/7595635/how-to-convert-polygon-data-into-line-segments-using-postgis

#SELECT ST_PointN(ls.geom, generate_series(1, ST_NPoints(ls.geom)-1)) as sp,
# ST_PointN(ls.geom, generate_series(2, ST_NPoints(ls.geom)  )) as ep,
# ls.gid
# from (select gid, ST_Boundary(st_geometryn(geom,1)) as geom from city) AS ls



# STEP 2 -
TEST
create table exterior as (
select gid, ST_ExteriorRing(st_geometryn(geom,1)) as geom from buildings)

create table exterior as select ST_ExteriorRing((ST_DUMP(ST_Union(geom))).geom) from buildings

for each building , select intersection and define as building

create table exterior9 as
select buildings.gid, ST_INTERSECTION(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ex.st_exteriorring) from buildings, exterior7 as ex where ST_INTERSECTS(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ex.st_exteriorring)  = true

select ST_ASTEXT(ST_INTERSECT(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ex.st_exteriorring)) from buildings, exterior7 as ex where gid = 418


# step1 version 1
create table segments as (SELECT ST_MakeLine(segments.sp,segments.ep) as geom, segments.building_id as building_id
FROM (SELECT ST_PointN(ls.geom, generate_series(1, ST_NPoints(ls.geom)-1)) as sp,
 ST_PointN(ls.geom, generate_series(2, ST_NPoints(ls.geom)  )) as ep,
 ls.gid as building_id
from (select gid, ST_Boundary(st_geometryn(geom,1)) as geom from buildings) AS ls) as segments);

# step1 version 2 --  only exterior rings --
create table segments as (SELECT ST_MakeLine(segments.sp,segments.ep) as geom, segments.building_id as building_id
FROM (SELECT ST_PointN(ls.geom, generate_series(1, ST_NPoints(ls.geom)-1)) as sp,
 ST_PointN(ls.geom, generate_series(2, ST_NPoints(ls.geom)  )) as ep,
 ls.gid as building_id
from (select gid, ST_ExteriorRing(st_geometryn(geom,1)) as geom from city) AS ls) as segments);

# geography
create table segments3 as (SELECT Geography(ST_Transform(ST_MakeLine(segments.sp,segments.ep),4326)) as geom, segments.building_id as building_id
FROM (

SELECT ST_PointN(ls.geom, generate_series(1, ST_NPoints(ls.geom)-1)) as sp,
 ST_PointN(ls.geom, generate_series(2, ST_NPoints(ls.geom)  )) as ep,
 ls.gid as building_id
from (select gid, ST_ExteriorRing(st_geometryn(geom,1)) as geom from city) AS ls) as segments);

ALTER TABLE segments ADD COLUMN gid SERIAL;
ALTER TABLE segments ADD PRIMARY KEY (gid);
UPDATE segments SET geom=ST_SetSRID(geom,4326);
CREATE INDEX segments_geom_gist ON segments USING gist (geom);
SELECT AddGeometryColumn("segments",'geom',4326, 'LINESTRING', 2);


create table within2 as (SELECT s.id, s.geom
	FROM segments s
		LEFT JOIN rays r ON ST_DWithin(s.geom,r.geom, 0.00001)) as candidates


SELECT DISTINCT ON (s.gid) s.gid, s.school_name, s.the_geom, h.hospital_name
	FROM schools s
		LEFT JOIN hospitals h ON ST_DWithin(s.the_geom, h.the_geom, 3000)
	ORDER BY s.gid, ST_Distance(s.the_geom, h.the_geom);


cps.point

select cps.r_id, cps.point as intersection_geom, cps.s_geom as segment_geom, cps.s_id, ST_DISTANCE(cps.point, cps.r_geom) as distance
from (SELECT r.id as r_id, r.geom as r_geom, s.gid as s_id, s.geom as s_geom , ST_ClosestPoint(s.geom,r.geom) as point
	FROM segments s
		inner JOIN rays r ON ST_DWithin(s.geom,r.geom, 0.00001)) as cps order by distance


select distinct on (ray_id) ray_id,  segment_id, inter_point, ST_DISTANCE(inter_point,obs_point) as distance from (SELECT r.id as r_id, s.gid as seg_id, ST_ClosestPoint(s.geom,r.geom) as inter_point, p.latlng as obs_point
	FROM rays r
		inner JOIN segments s ON ST_DWithin(s.geom,r.geom, 0.00001) INNER JOIN panos p on p.id=r.pano_id) as candidate
		order by candidate.r_id, distance asc

180 + (180-166) = 194
p droite -166
p gauche -121 180 + (180-121) = 239

select distinct on (ray_id)
c.pano_id as pano_id,
c.ray_id as ray_id,
c.seg_id as segment_id,
c.building_id as building_id,
c.inter_point,

-- Find the closest intersection
ST_DISTANCE(c.inter_point,c.obs_point) as distance,

-- Find pov angle
degrees(ST_Azimuth(c.obs_point, ST_PointN(c.seg_geom,1))) as angle_p2,
degrees(ST_Azimuth(c.obs_point, ST_PointN(c.seg_geom,2))) as angle_p1

from (SELECT r.id as ray_id, s.gid as seg_id, s.building_id as building_id, s.geom as seg_geom, ST_ClosestPoint(s.geom,r.geom) as inter_point, p.id as pano_id, p.latlng as obs_point
	FROM rays r
		inner JOIN segments s ON ST_DWithin(s.geom,r.geom, 0.00001) INNER JOIN panos p on p.id=r.pano_id) as c

--
order by c.ray_id, distance asc

3328*(79.7-110.23+180)/360 = 2400
3328*(238-110.23+180)/360= 2845


190 = 79.77
-110.23 = 127.77
as angle_p1


pov_building
id
pano_id
ray_id
segment_id
inter_point = geom
building_id
range_start
range_end


#.. need to add coloumn add

CREATE INDEX segments_geom_gist ON segments USING gist (geom);

   gid serial NOT NULL,
  CONSTRAINT serial_gid PRIMARY KEY (gid)

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'gsv_cutter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gsv_cutter

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
