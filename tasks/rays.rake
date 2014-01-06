namespace :rays do

	# Why latlng and not original_latlng
  	# check the position of pano i2ZO7ViS6lGryph0iLNqng on the map 
  	# and then the visual representation

	point_type = "latlng"

	# field of view  (in degree)
	pov_deg = 100.0 #(1.5 * 180.0/Math::PI).round

	# ray distance (in meter)
	ray_distance = 30.0 

	# the time period  selected (from 1 to 10. cf APUR database)
	period_time = 1

	resolution = 1.0

	desc "step 0 - setup sql Structure"
	task :setup => ["standalone:connection"] do
		puts " step 0 - building structure"

		sql = %Q{
			DROP  table panos_facades CASCADE ;
			DROP table rays_facades CASCADE ;
			DROP table   rays CASCADE ;
			
			CREATE TABLE rays (
			  id serial NOT NULL,
			  pano_id integer,
			  geom geography(LineString,4326),
			  detection_id integer,
			  angle integer,
			  relative_id integer,
			  type integer,
			  CONSTRAINT rays_tmp_pkey PRIMARY KEY (id)
			);
			CREATE INDEX index_rays_tmp_on_geom ON rays USING gist (geom);
			create index on rays (relative_id);

			create table rays_facades(
		    id serial NOT NULL,
		    ray_id      bigint,
		    facade_id bigint,
		    geom geometry('Point',4326),
		    distance double precision,
		    CONSTRAINT rays_facades_pkey PRIMARY KEY (id)
			);
			CREATE INDEX rays_facades_geom_gist ON rays_facades USING gist (geom);
			CREATE INDEX rays_facades_ray_id ON rays_facades USING btree (ray_id);
		  CREATE UNIQUE INDEX unique_rays_facades ON rays_facades (ray_id, facade_id);

			create table panos_facades(
				id serial not null,
				pano_id int,
				facade_id int,
				absolute_start int,
				absolute_end int,
				relative_start int,
				relative_end int,

				start_ray_id int,
				center_ray_id int,
				end_ray_id int,

				geom geometry('LINESTRING',4326),
				distance int,
				pov_angle double precision, field of view angle
				facade_angle double precision, angle with the facade (90deg is perfect)

				facade_time_period integer,
				CONSTRAINT panos_facades_pkey PRIMARY KEY (id)
			);
			CREATE INDEX panos_facades_geom_gist ON panos_facades USING gist (geom);
			create index ON panos_facades(facade_time_period);
			create index ON panos_facades(distance);
			
			CREATE UNIQUE INDEX unique_panos_facades ON panos_facades (pano_id, facade_id);
		}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "reset all rays"
	task :reset => ["standalone:connection"] do
		sql = %Q{
			TRUNCATE TABLE rays; 
			TRUNCATE TABLE rays_facades;
			TRUNCATE TABLE panos_facades;
		}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "step 0.5 preselecting only GSV images inside a given spatial boundery"
	task :preselect_space => ["standalone:connection"] do
	puts "spatial preselection of candidates GSV images (points: #{point_type})"
	sql = %Q{
		UPDATE panos set within_selection = true where panos.id in (
			select panos.id
			from panos, selections where st_contains(selections.geom, panos.#{point_type}::geometry)) 
		}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "step 0.5 (optional - to be faster) preselecting only GSV images near facades built at a given time period"
	task :preselect_time => ["standalone:connection"] do
		period_time = 2
		# distance between gsv images and facades in meter
		puts "temporal preselection for period #{period_time} of candidates GSV images (points: #{point_type})"
		sql = %Q{
			UPDATE panos set close_period_#{period_time} = true 
			where panos.id in (
			panos.id from (select gid from buildings where	c_perconst = #{period_time}) b 
			inner join facades f on f.building_id =  b.gid
			left join (select id, #{point_type} from panos where within_selection = true) panos on ST_DWithin(ST_Pointn(f.geom,1), panos.#{point_type},0.0004)
				)}
		t = Time.now
		results = ActiveRecord::Base.connection.execute(sql)
		
		puts "#{results.cmd_tuples()} (#{(Time.now - t).to_i/60.0}mins)" 
	end

	desc "step [preselection] - aggregating the preselection"
	task :preselect_aggregate => ["standalone:connection"] do
		
		# distance between gsv images and facades in meter
		puts "step 0.5 - preselecting the candidates GSV images (points: #{point_type})"

		sql = %Q{
			UPDATE panos set selected = false where panos.id in (select p.id from panos p where p.selected = true);
			UPDATE panos set selected = true where panos.within_selection = true;
		}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "step 0.5 (optional - to be faster) preselecting only 1 given GSV image"
	task :preselect_specific => ["standalone:connection"] do
		
		# distance between gsv images and facades in meter
		puts "step 0.5 - preselecting the candidates GSV images (points: #{point_type})"

		sql = %Q{
			UPDATE panos set selected = false where panos.id in (select p.id from panos p where p.selected = true);
			UPDATE panos set selected = true where panos.id = 3324;
		}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "step 1 - generate rays for each GSV - (version full 360)"
	task :generate_360 => ["standalone:connection"] do

		# ray distance in meter
		# point = "original_latlng"
		# generating 360 x number of panoramic images (around millions of rays)
		sql = %Q{
			INSERT INTO RAYS (pano_id, geom)  SELECT panos.id as pano_id,
			ST_MakeLine(panos.#{point_type}::geometry,
			ST_Project(panos.#{point_type}, #{ray_distance}, radians(generate_series(1, 360)::double precision))::geometry) as geom
			from panos
			where panos.selected= true
		}
		
		results = ActiveRecord::Base.connection.execute(sql )
		p results.cmd_tuples()
	end

	desc "step 1 - generate rays for each GSV - version (only left + right sides)"
	task :generate_side => ["standalone:connection"] do
		
		# point = "original_latlng"
		sql = %Q{
		INSERT INTO RAYS (pano_id, geom, angle)
		SELECT panos.id as pano_id,
		  ST_MakeLine(panos.#{point_type}::geometry,
		  ST_Project(panos.#{point_type}, #{ray_distance}, radians((panos.yaw_deg + 90)::integer % 360))::geometry) as geom,
		  90
		from  panos where panos.selected= true
		UNION 
		SELECT panos.id as pano_id,
		  ST_MakeLine(panos.#{point_type}::geometry,
		  ST_Project(panos.#{point_type}, #{ray_distance}, radians((panos.yaw_deg+ 270)::integer % 360))::geometry) as geom,
		  270 from  panos where panos.selected= true
		}		
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "step 1 - generate rays for each GSV - version (only left + right sides resolution 1deg)"
	task :generate_side_full => ["standalone:connection"] do
		# point_type = "original_latlng"
		# ray distance in meter
		# rays resolution in deg 
		# resolution = 2  => 1 ray for every 2 degrees
		
		nb_rays = (pov_deg / resolution).round
		puts "step 1 - generate rays (POV: #{pov_deg} deg. / nb rays: #{nb_rays})"
		sql = %Q{
		INSERT INTO RAYS (pano_id, geom, relative_id, type)
		SELECT panos.id as pano_id,
		  ST_MakeLine(
		  	panos.#{point_type}::geometry,
		  	ST_Project(
		  		panos.#{point_type}, 
		  		#{ray_distance}, 
		  		radians(mod((relative.id * #{resolution} + panos.yaw_deg + 90 - #{pov_deg/2.0})::numeric,360))
		  	)::geometry) as geom,
				relative.id,
				1
		from  
		panos, 
		(SELECT generate_series(1, #{nb_rays}) as id) as relative
		where panos.selected = true
		UNION 
		SELECT panos.id as pano_id,
		  ST_MakeLine(panos.#{point_type}::geometry,
		  ST_Project(panos.#{point_type}, #{ray_distance}, 
		  	radians(mod((relative.id * #{resolution} + panos.yaw_deg + 270 - #{pov_deg/2.0})::numeric,360))
		  	)::geometry) as geom,
				relative.id,
				0
		from
		panos, 
		(SELECT generate_series(1, #{nb_rays}) as id) as relative
		where panos.selected = true
		}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end

	desc "step 2 - compute intersection rays <-> facades "
	task :compute_intersection => ["standalone:connection"] do
		
		puts "step 2 - compute intersections rays <-> facades"

		sql = %Q{
			INSERT INTO rays_facades (ray_id, facade_id, geom, distance)
			SELECT DISTINCT ON (rays.id) inter.ray_id, inter.facade_id, inter.point::geometry, 
			    st_distance(st_pointn(rays.geom::geometry, 1)::geography, inter.point) AS distance
			   FROM ( SELECT r.id AS ray_id, 
			            s.id AS facade_id, 
			            (st_dump(st_intersection(s.geom::geography, r.geom)::geometry)).geom::geography AS point
			           FROM rays as r
			      JOIN facades s ON st_dwithin(s.geom, st_pointn(r.geom::geometry, 1), 0.0004) AND st_intersects(s.geom::geography, r.geom)) inter
			   JOIN rays ON rays.id = inter.ray_id
			  ORDER BY rays.id, st_distance(st_pointn(rays.geom::geometry, 1)::geography, inter.point);
			}
		results = ActiveRecord::Base.connection.execute(sql)
		p results.cmd_tuples()
	end


	desc "step 3 - compute visible facades (GSV images <-> facades relationship)"
	task :compute_gsv_angle => ["standalone:connection"] do
		[1,7].each do | period_time|
				compute_gsv_angle(period_time, point_type)
		end	
	end

	
	desc "step 4 - cut or mark GSV images <-> facades relationship"
	task :cut_pov => ["standalone:connection"] do
		[1, 2, 3, 5,6,7,8,9,10,11].each do | period_time|
			cut_pov(period_time, pov_deg, point_type)
		end	
	end

	desc "all the steps"
	task :batch => ["standalone:connection"] do
		# period_time = 3
		# point_type = "latlng"
		# Rake.application['rays:setup'].invoke()
		# Rake.application['rays:preselect'].invoke()
		# Rake.application['rays:generate_side_full'].invoke()
		
		# time = Time.now
		# Rake.application['rays:compute_intersection'].invoke()
		# puts "took #{(Time.now - time).to_i/60}"
		
			time = Time.now
			compute_gsv_angle(6, point_type)
			puts "took #{(Time.now - time).to_i/60.0} mins"
	
			time = Time.now
			compute_gsv_angle(7, point_type)
			puts "took #{(Time.now - time).to_i/60.0} mins"

		#	period_time = 5
		#		time = Time.now
#			Rake.application['rays:compute_gsv_angle'].invoke()
#			puts "took #{(Time.now - time).to_i/60.0} mins"
		# time = Time.now
		# Rake.application['rays:cut_pov'].invoke()
		# puts "took #{(Time.now - time).to_i/60}"
	end


 	desc "test"
	task :test => ["standalone:connection"] do	
		pano = Pano.find(764) 
		pano.download()
		pano.generate_ray(90, 40, 3)
		t = Tool.new(pano.filename, -180.0,180.0)
		t.mark_angle(90)
		PanosFacade.where({pano_id:764}).each do | pf|
			p t.mark_angle(pf.relative_start + 20, "green")
			p t.mark_angle(pf.relative_end + 20, "green")			 
		end
	end

	desc "test"
	task :test_pitch => ["standalone:connection"] do	
		pano = Pano.find(160)
		pano.download()
		#pano_yaw_deg="19.4" tilt_yaw_deg="22.71" tilt_pitch_deg="3.83"
		p pano.steep_angle 
		pano = Pano.find(24)
		#pano_yaw_deg="207.58" tilt_yaw_deg="19.98" tilt_pitch_deg="3.47"
		pano.download()
		p pano.steep_angle
	end

	desc "visualise cuts"
	task :visualise_cut => ["standalone:connection"] do	
		
		sql = %Q{
			select pf.* from panos_facades pf where pf.pano_id = 1701		
		}
 #order by pf.distance desc limit 2000
		# not to close because of 
		# but not to far to get 
		# 	
 	  pfs = PanosFacade.find_by_sql(sql)
 	   pfs.each do |pf|
 	   	pf.pano.mark_angle(pf.relative_start)
 			pf.pano.mark_angle(pf.relative_end)
 		end

 		 pfs = PanosFacade.find_by_sql(sql)
 		 pfs.each do |pf|
 		 	output_image = "#{pf.pano.panoID}_#{pf.facade_id}.jpg"	
 	   	pf.pano.cut_angle(pf.relative_start, pf.relative_end, output_image)
 		end

	end


def cut_pov(period_time, pov_deg, point_type)
		require 'parallel'
		puts " step 4 - cut images for period #{period_time}"		
		output_path = "/Users/maisonne/Documents/work/gsv_cutter/results/images/period_#{period_time}/"
		if File.exist?(output_path)
			puts " deleting directory"
			FileUtils.remove_dir(output_path, force: true)
		end
		Dir.mkdir(output_path)	
	
		pano_id = nil
		sides_images = {}
		facade_angle_tolerance = 10
		distance_min = 5.0
		distance_max = 15.0

		sql = %Q{
			select pf.*, (2 * (pf.distance - #{distance_min})/(#{distance_max-distance_min}) + 4 * pf.pov_angle/#{pov_deg} + (#{facade_angle_tolerance} - abs(pf.facade_angle - 90))) as score from 
			(select gid, c_perconst from buildings where c_perconst = #{period_time}) buildings
			inner join facades f on f.building_id = buildings.gid
			inner join panos_facades pf on pf.facade_id = f.id
			where pf.distance > 5 and pf.distance < 15 and pf.pov_angle > 50  and (abs(pf.facade_angle - 90) < 10)
			order by score desc limit 2000		
		}
 #order by pf.distance desc limit 2000
		# not to close because of 
		# but not to far to get 
		# 	
 	  pfs = PanosFacade.find_by_sql(sql)

 	  puts " #{pfs.size} buildings with such criteria for period #{period_time}"
 	  
 	  # download panoramic images
 	  panos = pfs.collect(&:pano)
 	  uniq_panos = panos.uniq
 	  valid_panos = []
 	  Parallel.map(panos, :in_threads => 4) do |pano|
 	 		valid_panos << pano.id if (pano.download("images/"))
 	  end

		# preparing dataset
		bp = Tool::Batch.new
 	  side_images = []
 	  pfs.each do |pf|
 	  	if valid_panos.include?(pf.pano_id)
	 	  	# pitch_deg = pf.pitch_from_height(3.0) # computer pitch deg to get the height at x meters from the ground (removing car/ ground level)
	 	  	pitch_deg = 0
	 	  	puts "pitch deg: #{pitch_deg}"
	 	  	fullpath = "images/#{pf.pano.filename}"
	 	  	side_image = bp.add(fullpath, ((pf.side == :left)? -90.0: 90.0), pov_deg, pitch_deg)
	 	  	side_images << { pf: pf, side: ((pf.side == :left)? -90.0: 90.0), side_image_path: side_image}	
	 	  end
 	  end
 	 	bp.run

 	  # project to the right side 	
 	  side_images.each { |si|
	 		pf = si[:pf]
	 		id = pf.facade_id.to_s+"_"+pf.pano_id.to_s 
 	  	output_image = "results/images/period_#{pf.facade_time_period}/"+ id+".jpg"	  	
 	  	unless File.exists?(output_image)
			begin
				side_image = pf.pano.side_image(si[:side], pov_deg, si[:side_image_path])
				side_image.cut_angles(pf.relative_start, pf.relative_end, output_image)
			rescue Exception => e 
				p e.message
			end
			else
				puts "final image already existing"
			end

	 	 }
	end

	def compute_facade_angle() 
		half_pov = pov_deg / 2
		sql = %Q{UPDATE panos_facades
				SET facade_angle = q.facade_angle
				FROM 
				(select q.id, abs(degrees(ST_Azimuth(start_point::geography,center_point::geography)) - degrees(ST_Azimuth(car_point::geography,center_point::geography))) 
					as facade_angle from (select pf.id, ST_PointN(rays.geom::geometry,1) 
						as car_point, pf.start_point, rf.geom as center_point 
						from (select pf.*, rays.type, rf.geom as start_point 
							from panos_facades pf inner join rays_facades rf on rf.id=pf.start_ray_id inner join rays on rays.id=rf.ray_id) as pf 
				inner join rays on rays.pano_id = pf.pano_id  
				inner join rays_facades rf on rf.ray_id=rays.id 
				where rays.relative_id = #{half_pov} and rays.type = pf.type) as q ) as q
				WHERE panos_facades.id=q.id}
	results = ActiveRecord::Base.connection.select_rows(sql)
	end

	def compute_gsv_angle(period_time, point_type)
		
		puts "step 3 - compute visible facades of buildings of time period #{period_time}"

		sql = %Q{
				select p.id,
				rf.facade_id, 
				degrees(ST_Azimuth(p.#{point_type}::geography, rf.geom::geography)) as degree,
				p.yaw_deg,
				rf.id,
				
				ST_ASTEXT(rf.geom),
					rf.distance,
					buildings.c_perconst
					from 
					(select gid, c_perconst from buildings where c_perconst = #{period_time}) buildings
				inner join facades f on f.building_id = buildings.gid
				inner join rays_facades rf on rf.facade_id = f.id
				inner join rays on rf.ray_id = rays.id 
				inner join panos p on p.id = rays.pano_id
					order by p.id, rf.facade_id, rays.relative_id
				}
				# order by p.id, rf.ray_id, rf.facade_id
		results = ActiveRecord::Base.connection.select_rows(sql)
		resolution = 1
		i = 0
		for_each_panosFacade(results) do |pano_id, facade_id, rows|
		 	pf = PanosFacade.create(pano: Pano.find(pano_id), 
		 		facade_id: facade_id, 
		 		facade_time_period: period_time,
		 		start_ray_id: rows[0][4].to_i,
		 		end_ray_id: rows[rows.length-1][4].to_i,
		 		center_ray_id: rows[rows.length/2][4].to_i,
		 		distance: rows[rows.length/2][6].to_f.to_i
		 		)

			# puts "pano: #{pano_id} - facade: #{facade_id} - # visible rays: #{rows.length}"
			if (rows.length > 1)
				[0, rows.length-1].each do |idx|
					row = rows[idx]
					ray_id  = row[4].to_i
					degree = row[2].to_f 				
					point  = row[5]
					distance  = row[6].to_f
					#puts "ray_id : #{ray_id}, #{degree}, #{relative_id}"
					pf.visible_at(point, degree.to_f, distance)
				end
				pf.post_processing(point_type) 
		 		i += 1
			end	
		end
		puts "#{i} panos facades created for time period #{period_time}."
	end

	def for_each_panosFacade(results)
		current = {id: nil}
		results.each do | row|
			# p row
			# extract key
			pano_id = row[0]
			facade_id = row[1]
			relation_id = pano_id+"_"+facade_id	

			# new 
			if relation_id != current[:id]
				yield(current[:pano_id], current[:facade_id], current[:rows]) unless current[:id].nil?
				current = {id:relation_id, pano_id: pano_id, facade_id:facade_id, rows: []}
			end
			current[:rows] << row
		end
		yield(current[:pano_id], current[:facade_id], current[:rows]) unless current[:id].nil?
	end
end



# 

#-- build each facade (linestring) - (generating 4k meaningful lineString)
# insert into facades (building_id, geom)  (
# select
# buildings.gid, -- the associated building
# (ST_DUMP(ST_LineMerge(
# 	ST_INTERSECTION(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ext.outside_ring)
# 	))).geom as geom -- the facade geometry (linestring)
# from buildings,
# (select ST_ExteriorRing((ST_DUMP(ST_Union(geom))).geom) as outside_ring from buildings) as ext
#  where ST_INTERSECTS(ST_ExteriorRing(st_geometryn(buildings.geom,1)), ext.outside_ring)  = true
#  );
