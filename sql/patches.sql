-- general schema
CREATE TABLE detections  (
  id serial NOT NULL,
  left_angle double precision,
  right_angle double precision,
  detector_id integer,
  pano_id integer,
  building_id integer references buildings(gid),
  facade_id integer references facades(id),
  period_construction smallint,
  year_construction integer,
  geom geography(linestring),
  state integer,
  CONSTRAINT detections_pkey PRIMARY KEY (id)
);

CREATE INDEX on rays(type)

CREATE INDEX index_detections_on_geom ON detections USING gist (geom);


----
-- rays of detections of detector 6557
TRUNCATE TABLE rays;
INSERT INTO RAYS (pano_id, geom, detection_id, angle)  SELECT panos.id as pano_id,
	ST_MakeLine(panos.latlng::geometry,
	ST_Project(panos.latlng, 50, radians((panos.yaw_deg + detections.left_angle)::integer % 360.0))::geometry) as geom,
	detections.id,
	detections.left_angle
from detections inner join panos on detections.pano_id = panos.id where detector_id = 6557;


INSERT INTO RAYS (pano_id, geom, detection_id, angle)  SELECT panos.id as pano_id,
	ST_MakeLine(panos.latlng::geometry,
	ST_Project(panos.latlng, 50, radians((panos.yaw_deg + detections.right_angle)::integer % 360.0))::geometry) as geom,
	detections.id,
	detections.left_angle
from detections inner join panos on detections.pano_id = panos.id where detector_id = 6557;


-- simplification : middle of the width of the detection
TRUNCATE TABLE rays;
INSERT INTO RAYS (pano_id, geom, detection_id, angle, type)  SELECT panos.id as pano_id,
	ST_MakeLine(panos.latlng::geometry,
	ST_Project(panos.latlng, 50, radians((panos.yaw_deg + left_angle + (right_angle - left_angle)/2)::integer % 360.0))::geometry) as geom,
	detections.id,
	detections.left_angle
  1 as type
from detections inner join panos on detections.pano_id = panos.id 

#where detector_id = 6557;


-- test: middle of the image
INSERT INTO RAYS (pano_id, geom, detection_id, angle)  SELECT panos.id as pano_id,
	ST_MakeLine(panos.latlng::geometry,
	ST_Project(panos.latlng, 100, radians(panos.yaw_deg + 90))::geometry) as geom,
	detections.id,
	detections.left_angle
from detections inner join panos on detections.pano_id = panos.id


-- create a view
CREATE OR REPLACE VIEW patches_intersection as
select distinct on (rays.id) inter.* , rays.pano_id, ST_DISTANCE(ST_POINTN(rays.geom::geometry,1)::geography, inter.point) as distance
from
(SELECT r.id as ray_id, d.id as detection_id,
d.detector_id as detector_id,
 s.id as facade_id, s.building_id as building_id,
(ST_DUMP((ST_INTERSECTION(s.geom::geometry,r.geom))::geometry)).geom::geography as point
FROM (select * from rays where rays.type = 1) as r 
JOIN facades s ON 
ST_DWithin(s.geom, ST_PointN(r.geom::geometry,1),0.0004) and ST_Intersects(s.geom::geography,r.geom::geography) 
inner join detections d on d.id = r.detection_id) as inter 
inner join rays on rays.id = inter.ray_id order by rays.id, distance asc;





--
-- general schema
DROP TABLE improved_detections;
CREATE TABLE improved_detections (
  id serial NOT NULL,
  detection_id integer references detections(id),
  detector_id  integer,
  panoID character varying(255),
  score double precision,
  building_id integer references buildings(gid),
  
  location_detection  geometry(Point,4326) /*geography(Point),*/
  distance_detection double precision,

  year_construction integer,
  period_construction smallint,
  filename character varying(255),
  CONSTRAINT improved_detections2 PRIMARY KEY (id)
);
CREATE INDEX index_impr_detections_on_geom ON improved_detections USING gist (location_detection);


CREATE SELECT di.detector_id, b.c_perconst, count(*) from detection_intersection di inner join buildings b on b.gid = di.building_id group by di.detector_id, b.c_perconst


--Period of time
SELECT di.detector_id, b.c_perconst, count(*) from detection_intersection di inner join buildings b on b.gid = di.building_id group by di.detector_id, b.c_perconst

-- year of construction
SELECT di.detector_id, b.an_const, count(*) from detection_intersection di inner join buildings b on b.gid = di.building_id group by di.detector_id, b.an_const


# nb of detections  per detector
select count(*) as nb from detections group by detector_id order by nb desc
