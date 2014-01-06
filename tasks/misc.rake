namespace :misc do
desc "generate rays"
task :generate_rays => ["standalone:connection"] do
	i = 0
	Pano.where(selected:true).each do |pano|
		0.step(360, 5) do | ray_angle|
			pano.generate_ray(ray_angle,100)
		end
		i += 1
		puts "#{i} panorama done " if (i % 10) == 0
	end
end

desc "direction"
task :direction => ["standalone:connection"] do
	panos = Pano.all.each do | pano|
		pano.direction = pano.generate_postgis(0, 15)
		pano.save
	end

end

desc "visibility"
task :visibility => ["standalone:connection"] do
	panos = Pano.includes(:visible_rays  => [:facade]).where(selected: true)
	size = panos.size
	i = 0
	panos.each do |pano|
		i += 1
		puts "#{i} / #{size} " if (i % 10) == 0
		pano.building_povs
	end
end

desc "extract steep angle"
task :pitch => ["standalone:connection"] do
	# require 'json'
	require 'yaml'
	i = 0
		panos = Pano.where(selected: true).where("steep_angle is null").order("id asc")
		puts "panos #{panos.size} to process"
		panos.each { |pano|
				json_data = YAML.load(pano.raw_json)
				# p json_data
				pano.steep_angle = json_data["Projection"]["tilt_pitch_deg"].to_f
				pano.save
				i += 1
				puts i if (i % 1000) == 0
		 }

		#pano.save
end

desc "elevation"
task :elevation => ["standalone:connection"] do
	# require 'json'
	require 'yaml'
	# POINT (Lon Lat)
	# LAT=48, LNG = 2
	#{rand(10000)}
	Pano.where(selected: true).limit(10).each { |pano|
			json_data = YAML.load(pano.raw_json)
			pano.elevation = json_data["Location"]["elevation_wgs84_m"].to_f
			pano.save
	 }
		#pano.save
end

	desc "statistics - give nb of GSV imags + nb of facades for each time period"
	task :statistics => ["standalone:connection"] do
	 	sql = %Q{
	 		select facade_time_period, count(pf.id) as nb_views, count(distinct pf.pano_id) as nb_panos, count(distinct pf.facade_id) as visible_facades
			from panos_facades pf
			group by pf.facade_time_period
	 	}
	 	results = ActiveRecord::Base.connection.select_rows(sql)
	 	results.each{|row|
	 		p row
	 	}
	 		sql = %Q{
	 		select facade_time_period, count(pf.id) as nb_views, count(distinct pf.pano_id) as nb_panos, count(distinct pf.facade_id) as visible_facades
			from panos_facades pf
			where pf.distance < 4 
			group by pf.facade_time_period
	 	}
	 	results = ActiveRecord::Base.connection.select_rows(sql)
	 	results.each{|row|
	 		p row
	 	}


	sql = %Q{
		select 10 * s.d, (count(t.facade_angle) / 296677.0) * 100
	from generate_series(0, 17) s(d)
	left outer join panos_facades t on s.d = floor(t.facade_angle / 10)
	group by s.d
	order by s.d
	}
	results = ActiveRecord::Base.connection.select_rows(sql)
	 	results.each{|row|
	 		p row
	 	}
 

sql = %Q{
		select facade_time_period, s.d *5 as range, (count(t.distance)) as pourcentage
	from generate_series(0, 10) s(d)
	left outer join panos_facades t on s.d = floor(t.distance / 5)
	group by facade_time_period, s.d  
	order by facade_time_period, s.d
}
results = ActiveRecord::Base.connection.select_rows(sql)
	 	results.each{|row|
	 		p row
	 	}
	 		end
	 		
end