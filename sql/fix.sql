
ALTER TABLE panos ADD column latlngv2 geometry ('POINT', 4326);
UPDATE panos set latlngv2 = latlng::geometry; 
ALTER TABLE panos RENAME "latlng" to "latlng_old";
ALTER TABLE panos RENAME "latlngv2" to "latlng";
