
-- STEP 1 we compute a rays analysis
-- for each ray, we find the visible part of the ray i.e. the intersetion between the ray and the first/closest polygon

insert into visible_rays (scope, pano_id, ray_id, segment_id, building_id, inter_point , distance, raw_angle1, raw_angle2, rel_angle1, rel_angle2) select distinct on (ray_id)
ST_MakePolygon(ST_MakeLine(ARRAY[geometry(obs_point), ST_PointN(c.seg_geom,1),ST_PointN(c.seg_geom,2), geometry(obs_point)])) as scope,
c.pano_id as pano_id,
c.ray_id as ray_id,
c.seg_id as segment_id,
c.building_id as building_id,
c.inter_point,

-- Find the closest intersection
ST_DISTANCE(c.inter_point,c.obs_point) as distance,

-- Find pov angle
degrees(ST_Azimuth(c.obs_point, ST_PointN(c.seg_geom,1))) as raw_angle1,
degrees(ST_Azimuth(c.obs_point, ST_PointN(c.seg_geom,2))) as raw_angle2,

degrees(ST_Azimuth(c.obs_point, ST_PointN(c.seg_geom,1)))-c.panoPOV as rel_angle1,
degrees(ST_Azimuth(c.obs_point, ST_PointN(c.seg_geom,2)))-c.panoPOV as rel_angle2


from (SELECT r.id as ray_id,
s.gid as seg_id,
s.building_id as building_id,
s.geom as seg_geom,
ST_ClosestPoint(s.geom,r.geom) as inter_point,
p.id as pano_id,
p.yaw_deg as panoPOV,
p.latlng as obs_point
	FROM rays r
		inner JOIN segments s ON ST_DWithin(s.geom,r.geom, 0.00001) INNER JOIN panos p on p.id=r.pano_id) as c

--
order by c.ray_id, distance asc)insert into visibility_feature (pano_id, visibility) select  pano_id, sum(distance)/count(*) from visible_segments3 group by pano_id;

-- STEP 2: we compute the aggreation for each panorama
insert into visibility_feature (pano_id, visibility) select  pano_id, sum(distance)/count(*) from visible_segments3 group by pano_id;


-- insert into visibility_feature (pano_id, visibility)
--	select  rays.pano_id, sum(visibility_distance)/count(*)
--	from visible_rays as vr left join rays on vr.ray_id = rays.id
-- group by rays.pano_id;

CREATE VIEW visibility_feature as select rays.pano_id, sum(visibility_distance)/count(*) as visibility
	from visible_rays as vr left join rays on vr.ray_id = rays.id
 group by rays.pano_id;

CREATE TABLE visibility_feature_table as select rays.pano_id, panos.latlng, sum(visibility_distance)/count(*) as visibility
	from visible_rays as vr
	left join rays on vr.ray_id = rays.id
	inner join panos on rays.pano_id = panos.id
 group by rays.pano_id;

select * from panos as p inner join visibility_feature vf on p.id = vf.pano_id
