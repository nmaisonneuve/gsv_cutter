-- require rays_intersection.sql (table visible_rays)

create or replace view pov as
select panos.id as pano_id,
	facades.building_id,
	rays.id as ray_id,
	degrees(ST_Azimuth(panos.latlng::geography, vr.point::geography)) as degree,
	vr.point::geography
	from visible_rays as vr
	left join rays on vr.ray_id = rays.id
	left join facades on vr.facade_id = facades.id
	inner join panos on rays.pano_id = panos.id where facade_id is not null;

-- compute number of panorama showing each building
select building_id, count(*) as exposition from pov group by building_id order by exposition desc

-- compute range of angles for each visible buildings for each panorama (with at least a range of 2 rays = count(*) > 1)
select pano_id, building_id, min(degree) as min, max(degree) as max,
count(*) as nb_rays
from pov
group by pano_id, building_id having count(*) > 1
order by pano_id desc

-- compute range of angles for each visible buildings for each panorama (with at least a range of 2 rays = count(*) > 1)
-- + with point and ray id

-- sol 1
create table building_povs as SELECT pov_v2.* from (SELECT DISTINCT

      pano_id, building_id
      ,first_value(degree) OVER w AS min_degree
      ,first_value(point) OVER w AS min_ray
      ,last_value(degree)  OVER w AS max_degree
      ,last_value(point)  OVER w AS max_ray

FROM   pov
WINDOW w AS (PARTITION BY pano_id, building_id ORDER BY degree, ray_id
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
ORDER  BY 1) as pov_v2 where min_ray != max_ray

-- sol 3
select pano_id, building_id, ST_ASTEXT(ST_MakeLine(pov.point))
count(*) as nb_rays
from pov
group by pano_id, building_id having count(*) > 1
order by pano_id desc

-- sol 2
(select distinct on (pano_id, building_id) pano_id, building_id, ray_id, degree from pov
order by pano_id,building_id, degree desc) union all (select distinct on (pano_id, building_id) pano_id, building_id, ray_id, degree from pov
order by pano_id,building_id, degree asc) order by pano_id, building_id


-- sol2.1
create table visible_scope_v2 as (select pb.pano_id, building_id,
ST_MakePolygon(ST_MakeLine(ARRAY[p.latlng::geometry, min_ray::geometry, max_ray::geometry,p.latlng::geometry])) as scope
from building_povs pb
left join panos as p on pb.pano_id = p.id)


select pano_id, building_id, r1.id, r2.id
from pov_building pb
left join panos as p on pb.pano_id = p.id
left join rays as r1 on pb.min_ray_id = r1.id
left join rays as r2 on pb.min_ray_id = r2.id

group by pano_id, building_id


ST_MakePolygon(ST_MakeLine(ARRAY[panos::geography, ST_Project(panos::geography,min(degree)min_ray.inter::geography, max_ray.inter::geography])) as scope,
