namespace :detection do

	desc "export detection"
	task :export => ["standalone:connection"] do
		require 'csv'
		CSV.open("../data/detections/temporal_table_v3.csv", "wb") do |csv|
			csv << ["detection_id","detector_id", "score", "panoID", "year", "period", "filename","lat", "lng"]
		
		# if improved detection is empty
 sql = %Q{
INSERT INTO improved_detections (
detection_id,
detector_id,
panoID,
score,
building_id,
location_detection,
distance_detection,
year_construction,
period_construction,
filename)
(SELECT
ds.id as detection_id, 
ds.detector_id, 
ps."panoID", 
ds.score,
di.building_id, 
di.point as point_detection, 
di.distance as distance_to_point, 
bs.an_const::smallint as year_construction, 
bs.c_perconst::smallint  as period_construction, 
ds.filename
from detections  ds
left join detection_intersection di on di.detection_id = ds.id 
inner join buildings bs on di.building_id=bs.gid
inner join panos ps on ds.pano_id = ps.id);
}

ActiveRecord::Base.connection.execute(sql)

		#	ImprovedDetection.where(detector_id: detector_ids).each { |detection|
		ImprovedDetection.all.each { |detection|
			filename = "/#{detection.detector_id}/#{detection.panoid}_1.jpg"
			pano = Pano.where(panoID: detection.panoid).first

				csv << [detection.id, 
					detection.detector_id, 
					detection.score, 
					detection.panoid,
					detection.year_construction,
					 detection.period_construction,
					 filename,
					 pano.lat, pano.lng]
			}
		end
	end

	desc "import detection data to posgis"
	task :import => ["standalone:connection"] do
		require 'csv'
	#	for each detection
		# for each bounding box coordinate
			# determinating the angle of the bounding box.

	# width of the original GSV image (zoom 4)
	WIDTH = 6656.0

		# pov angle
	 	POVRAD = 1.5
	 	POVDEG = POVRAD * 180.0 / Math::PI
	 	REAL_WIDTH_CUTOUT = 936.0

	 	# TRUNCATE table detections CASCADE 

	 	# delete all detections
	 	Detection.delete_all
	 	
	 	i = 0
	 	j = 0
		CSV.foreach("../gsv_oldparis/results/valid_detections_v2.csv",:headers => true) do |row|
			  
		  puts "#{i} - #{i.to_f/j.to_f}" if (i % 100) == 0
		 
		  i += 1
 
		  pano = Pano.find_by_panoID(row[4])
		  if (pano.yaw_deg.nil?)
		  	 j += 1
		  else 
				cluster_id = row[5].to_i
				score = row[6].to_f
				side = row[7].to_i
				filename = row[8]
				x = row[0].to_f
				width = row[2].to_f
				# transform detection horizontal coordinates to relative angle ones
				# each coordinate ratio into its relative angle of the POV
				relative_start_angle = ( x / REAL_WIDTH_CUTOUT) * POVDEG
				width_angle = width / REAL_WIDTH_CUTOUT * POVDEG
				relative_end_angle = relative_start_angle + width_angle
				
				# the center of the point of view e.g.  either 90 or 270 degree 
				# of the center of the panoramic image
				angle_side_pov = side - POVDEG/2.0
		
				start_angle = (pano.yaw_deg + angle_side_pov + relative_start_angle + 360) % 360
				end_angle = (pano.yaw_deg + angle_side_pov + relative_end_angle + 360) % 360
				

				detection = Detection.create(
					pano_id: pano.id,
					left_angle: start_angle,
					right_angle: end_angle,
					detector_id: cluster_id,
					score: score,
					filename: filename,
					state: 1)
				
				# middle of the width of the detection
				center_angle = (start_angle + width_angle/2.0 + 360) % 360

				sql = %{
						TRUNCATE TABLE rays;
						INSERT INTO RAYS (pano_id, geom, detection_id, angle)  SELECT panos.id as pano_id,
						  ST_MakeLine(panos.latlng::geometry,
						  ST_Project(panos.latlng, 50, radians(())::geometry) as geom,
						  detections.id,
						  detections.left_angle
						from detections inner join panos on detections.pano_id = panos.id}
			end
		end
	end

	desc "import detection data to posgis"
	task :import_old => ["standalone:connection"] do
		require 'csv'

		CSV.open("./data/detections/valid_detection.csv", "wb") do |csv|
			output.each do | row|
				csv << row
			end
		end
	end

	def generate_ray(x)
			angle_pov = row[5]
			panoID = row[6]
			angle_detection = angle_pov - POVDEG/2.0 + POVDE
	end

end
