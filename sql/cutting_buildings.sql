
/*
SELECT a subset of the panos
*/
UPDATE panos SET selected = false;
CREATE INDEX ON panos (selected);
UPDATE panos SET selected = true from selections where panos.image_date > '2010-06-01' and  ST_Contains(selections.geom, panos.latlng::geometry)

/*
(VERSION 1)Create rays with a given resolution and depth 
*/
TRUNCATE TABLE rays;
INSERT INTO RAYS (pano_id, geom)  SELECT panos.id as pano_id,
	ST_MakeLine(panos.latlng::geometry,
	ST_Project(panos.latlng, 50, radians(generate_series(1, 360)::double precision))::geometry) as geom
from panos where panos.selected = true



SELECT DISTINCT ON (rays.id) inter.ray_id, inter.facade_id, inter.point, 
    rays.pano_id, 
    st_distance(st_pointn(rays.geom::geometry, 1)::geography, inter.point) AS distance
   FROM ( SELECT r.id AS ray_id, d.id AS detection_id, d.detector_id, 
            s.id AS facade_id, s.building_id, 
            (st_dump(st_intersection(s.geom::geography, r.geom)::geometry)).geom::geography AS point
           FROM ( SELECT rays.id, rays.pano_id, rays.geom, rays.detection_id, 
                    rays.angle, rays.type
                   FROM rays
                  WHERE rays.type = 1) r
      JOIN facades s ON st_dwithin(s.geom, st_pointn(r.geom::geometry, 1), 0.0004::double precision) AND st_intersects(s.geom::geography, r.geom)
   JOIN detections d ON d.id = r.detection_id) inter
   JOIN rays ON rays.id = inter.ray_id
  ORDER BY rays.id, st_distance(st_pointn(rays.geom::geometry, 1)::geography, inter.point);


SELECT r.id as ray_id, s.id as facade_id, s.building_id as building_id,
(ST_DUMP((ST_INTERSECTION(s.geom::geometry,r.geom))::geometry)).geom as point
FROM rays r JOIN facades s ON ST_INTERSECTS(r.geom, s.geom);

SELECT r.id as ray_id, s.id as facade_id,
ST_DISTANCE(ST_INTERSECTION(s.geom::geometry,r.geom)::geography, ST_StartPoint(r.geom::geometry)) as distance
FROM (SELECT * from rays where pano_id in (select panos.id from panos where panos.selected = true limit 10)) 
 as r JOIN facades s ON ST_INTERSECTS(r.geom, s.geom) order by distance


TRUNCATE TABLE visible_rays;
insert into visible_rays  (ray_id, pano_id, facade_id, point, distance)
select distinct on (rays.id)  rays.id, rays.pano_id, inter.facade_id, inter.point,
ST_DISTANCE(ST_POINTN(rays.geom::geometry,1)::geography, point::geography) as distance from rays
inner join rays_intersection as inter on rays.id = inter.ray_id


/* subpart */
TRUNCATE TABLE visible_rays;
insert into visible_rays  (ray_id, pano_id, facade_id, point, distance)
select distinct on (rays.id)  rays.id, rays.pano_id, inter.facade_id, inter.point,
ST_DISTANCE(ST_POINTN(rays.geom::geometry,1)::geography, point::geography) as distance 
from 
 (SELECT * rays from rays where pano_id in (select panos.id from panos where panos.selected = true limit 10)) as rays
inner join rays_intersection as inter on rays.id = inter.ray_id;


SELECT r.id as ray_id, s.id as facade_id
ST_DISTANCE(ST_INTERSECTION(s.geom::geometry,r.geom))::geometry)) as distance
FROM (SELECT * rays from rays limit 10) rays r JOIN facades s ON ST_INTERSECTS(r.geom, s.geom) order by distance


 CREATE TABLE facades_images(
    id serial NOT NULL,
    pano_id bigint,
    facade_id bigint,
    left_angle double precision,
    right_angle double precision,
    left_point geography(Point),
    left_point geography(Point),
    distance double precision,
    CONSTRAINT facades_images_pkey PRIMARY KEY (id)
);
#CREATE INDEX v_rays_geom_gist ON facades_images USING gist (point);

#panoID, left, right, buildingID


/*
 (VERSION 2) only takes the 2 borders of a facade and see if for each panos there is no intersection create 
*/
drop table facades_panos_v2;
create table facades_panos_v2 (
 id serial,
pano_id int,
facade_id int ,
 pov geometry('LINESTRING', 4326),
 nb_inter int,
 PRIMARY KEY(id)
);

TRUNCATE TABLE facades_panos_v2;
INSERT INTO facades_panos_v2 (pano_id, facade_id, pov, nb_inter) select distinct
 p.pano_id, facade_id, p.pov, count(facades.id) as inter
from (

TRUNCATE TABLE facades_panos_v2;
INSERT INTO facades_panos_v2 (pano_id, facade_id, pov) select 
panos.id as pano_id,
facades.id as facade_id, 
ST_SETSRID(
ST_MAKELINE(
ARRAY[
ST_PROJECT(panos.latlng::geography, 
    ST_DISTANCE(panos.latlng::geography, ST_StartPoint(geom)::geography) * 0.95,
    ST_Azimuth(panos.latlng::geography, ST_StartPoint(geom)::geography)
)::geometry,

panos.latlng,

ST_PROJECT(panos.latlng::geography, 
    ST_DISTANCE(panos.latlng::geography, ST_EndPoint(geom)::geography) * 0.95,
    ST_Azimuth(panos.latlng::geography, ST_EndPoint(geom)::geography)
)::geometry]),4326) as pov


from (select * from panos where panos.selected = true limit 20) as panos 
inner join facades ON ST_DWithin(panos.latlng::geography,facades.geom::geography, 30)

from panos , facades where panos.id= 397535 and facades.id = 61235;

TRUNCATE TABLE facades_panos_v2;
INSERT INTO facades_panos_v2 (pano_id, facade_id,pov) select 
panos.id as pano_id,
facades.id as facade_id, 
ST_MAKELINE(panos.latlng,ST_PROJECT(panos.latlng::geography, 
    ST_DISTANCE(panos.latlng::geography, ST_StartPoint(geom::geometry)::geography),
    ST_Azimuth(panos.latlng, ST_StartPoint(geom::geometry)))::geometry) as pov
from (select * from panos where panos.selected = true limit 20) as panos 
inner join facades ON ST_DWithin(panos.latlng::geography,facades.geom::geography, 30)
    , 
    panos.latlng::geometry, ST_EndPoint(geom::geometry)]),4326) as pov 
from facades inner join panos on ST_DWithin(panos.latlng,facades.geom, 50) 
where panos.selected = true limit 100) as p ,
facades  inner join p on ST_DWithin(p.pov,facades.geom, 50) 
where ST_Intersects(facades.geom,p.pov) = true and facades.id != p.facade_id group by p.pano_id, facade_id, p.pov  order by p.pano_id, p.facade_id



TRUNCATE TABLE facades_panos_v2;
INSERT INTO facades_panos_v2 (pano_id, facade_id, pov, nb_inter) select distinct
 p.pano_id, facade_id, p.pov, count(facades.id) as inter
from (select facades.id as facade_id, panos.id as pano_id, 
ST_SetSRID(ST_MakeLine(ARRAY[ST_StartPoint(geom::geometry), 
    panos.latlng::geometry, ST_EndPoint(geom::geometry)]),4326) as pov 
from facades inner join panos on ST_DWithin(panos.latlng,facades.geom, 50) 
where panos.selected = true limit 100) as p ,
facades  inner join p on ST_DWithin(p.pov,facades.geom, 50) 
where ST_Intersects(facades.geom,p.pov) = true and facades.id != p.facade_id group by p.pano_id, facade_id, p.pov  order by p.pano_id, p.facade_id


