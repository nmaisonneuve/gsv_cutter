-- general schema
DROP TABLE rays;
CREATE TABLE rays (
  id serial NOT NULL,
  pano_id integer,
  geom geography(LineString),
  detection_id integer,
  angle integer,
  type integer,
  CONSTRAINT rays_pkey PRIMARY KEY (id)
);
CREATE INDEX index_rays_on_geom ON rays USING gist (geom);

-- VERSION 1. Create rays with a given resolution and depth
TRUNCATE TABLE rays;
INSERT INTO RAYS (pano_id, geom)  SELECT panos.id as pano_id,
	ST_MakeLine(panos.latlng::geometry,
	ST_Project(panos.latlng, 50, radians(generate_series(1, 360)::double precision))::geometry) as geom
from panos
where panos.image_date > '2010-06-01'


-- VERSION 2. generate rays from 90 and 270 angles
TRUNCATE TABLE rays;
INSERT INTO RAYS (pano_id, geom, angle)  SELECT panos.id as pano_id,
  ST_MakeLine(panos.latlng::geometry,
  ST_Project(panos.latlng, 30, radians((panos.yaw_deg + 90)::integer % 360))::geometry) as geom,
  90
from  panos where panos.image_date > '2010-06-01'
UNION SELECT panos.id as pano_id,
  ST_MakeLine(panos.latlng::geometry,
  ST_Project(panos.latlng, 30, radians((panos.yaw_deg+ 270)::integer % 360))::geometry) as geom,
  270
from  panos where panos.image_date> '2010-06-01'



-- create the interesection
SET LOCAL work_mem = '96MB';
CREATE OR REPLACE VIEW rays_intersection as
SELECT r.id as ray_id, s.id as facade_id, s.building_id as building_id,
(ST_DUMP((ST_INTERSECTION(s.geom::geometry,r.geom))::geometry)).geom as point
FROM rays r JOIN facades s ON ST_INTERSECTS(r.geom, s.geom);

CREATE TABLE visible_rays (
    id serial NOT NULL,
    ray_id      bigint,
    pano_id bigint,
    facade_id bigint,
    building_id bigint,
    point geography(Point),
    distance double precision,
    CONSTRAINT visible_rays_pkey PRIMARY KEY (id)
);



-- current: distance in radian (fater but long query: 2200 seconds for 5th arrondissement)
-- remove ::geometry for distance in meter
TRUNCATE TABLE visible_rays;
insert into visible_rays  (ray_id, pano_id, facade_id, point, distance)
select distinct on (rays.id)  rays.id, rays.pano_id, inter.facade_id, inter.point,
ST_DISTANCE(ST_POINTN(rays.geom::geometry,1)::geography, point::geography) as distance from rays
inner join rays_intersection as inter on rays.id = inter.ray_id
order by rays.id, distance asc;

-- update visibility of rays with no intersection
update visible_rays set distance = ST_LENGTH(vr.geom) where vr.facade_id is null

-- testing
select * from visible_rays as vr where vr.facade_id is null

-- v1.01
insert into visible_rays  (ray_id, pano_id, facade_id, building_id, point, distance)
select distinct on (ray_id)  inter.ray_id, inter.pano_id, inter.facade_id,
inter.building_id,
 inter.point,
ST_DISTANCE(inter.ray_point::geography, inter.point::geography) as distance
from (SELECT r.id as ray_id, s.id as facade_id, r.pano_id as pano_id, s.building_id as building_id,
(ST_DUMP((ST_INTERSECTION(s.geom::geometry,r.geom))::geometry)).geom as point, ST_POINTN(r.geom::geometry,1) as ray_point
FROM rays r JOIN facades as s ON ST_INTERSECTS(r.geom, s.geom)
where r.pano_id = 307928
) as inter
order by ray_id, distance asc;

