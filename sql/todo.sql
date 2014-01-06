select pf.id, re.geom as end_id, pf.start_ray_id, rs.geom, degrees(ST_Azimuth(re.geom, rs.geom)) as angle_facade, degrees(ST_Azimuth(rc.geom, p.latlng)) as angle_view, (degrees(ST_Azimuth(re.geom, rs.geom)) - degrees(ST_Azimuth(rc.geom, p.latlng))) as difference
from panos_facades pf

inner join rays_facades rs on rs.id = pf.start_ray_id
inner join rays_facades re on re.id = pf.end_ray_id
inner join rays_facades rc on rc.id = pf.center_ray_id
inner join panos p on p.id = pf.pano_id

where  pf.id = 707243 or pf.id = 718737

limit 3
