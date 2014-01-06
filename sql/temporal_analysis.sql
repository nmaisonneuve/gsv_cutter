select an_const, count(facades.*), sum(ST_LENGTH(facades.geom)) as facade_length from buildings
join facades on buildings.gid = facades.building_id group by an_const order by facade_length;

select c_perconst, count(facades.*), round(sum(ST_LENGTH(facades.geom))) as facade_length from buildings
join facades on buildings.gid = facades.building_id group by c_perconst order by facade_length

select c_perconst as period, count(facades.*) as freq, sum(ST_LENGTH(facades.geom)) as facade_length from buildings
join facades on buildings.gid = facades.building_id, (select ST_SetSRID(ST_EXTENT(location_detection),4326) as box from improved_detections) as selected_area
where ST_Intersects(facades.geom,selected_area.box) group by c_perconst order by c_perconst




select facades.* from buildings ST_LENGTH(facades.geom)  as facade_length 
join facades on buildings.gid = facades.building_id where c_perconst = 1 order by facade_length



	
