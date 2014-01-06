namespace :export do

	task :gene_rays => ["standalone:connection"]   do
		require 'csv'
		Ray.delete_all

		# Pano.update_all("selected = false")
		puts "generating rays done"
		CSV.foreach("./data/detections/pano_found.csv") do |panoID|
				pano = Pano.find_by_panoID(panoID)
				pano.generate_ray(90.0, 100)
				pano.generate_ray(90.0 - (POVDEG / 2.0), 100)
				pano.generate_ray(90.0 + (POVDEG / 2.0), 100)
				pano.generate_ray(270.0, 100)

		end
	end



	def cutout_to_original(pixel, type = 90)
		original_cutout_pixel = pixel.to_f * RATIO_DISTORTION
		pixel = case (type)
			when 90 then LEFT_PIXEL_90 + original_cutout_pixel
			when 270 then LEFT_PIXEL_270 + original_cutout_pixel
		end
		pixel
	end

  def pixel_to_angle(pixel)

    pixel_center = WIDTH.to_f/2.0

    relative_pixel = pixel - pixel_center

    relative_angle = (pixel - pixel_center) * 360 / WIDTH.to_f # / 2  / 180.0

    # absolute_angle = ( YAWDEG + relative_angle) % 360)
		relative_angle
    # absolute_angle
  end

	desc "transfert redis to postgis"
	task :redis => ["standalone:connection"]   do
		require 'redis'
		require 'json'

		redis = Redis.new(:driver =>  :hiredis) #:ruby
		i = 0
		redis.smembers("area:paris_v3").each do |panoID|

			json = JSON.parse(redis.get(panoID))

			pano = Pano.find_or_create_by_panoID(panoID)

			if pano.processed_at.nil?
				i += 1

				puts "#{i}" if  (i % 1000) ==0

				links_ids = []
		  	json["Links"].each { |link_json|
		  		links_ids << link_json["panoId"] if link_json["scene"] == "0"
		  	}

		  	date = json["Data"]["image_date"]
		  	date = Date.strptime(date, '%Y-%m')

				pano.update_attributes({
			  	image_date: date,
			    yaw_deg: json["Projection"]["pano_yaw_deg"].to_f,
			    original_latlng: "POINT (#{json["Location"]["original_lng"]} #{json["Location"]["original_lat"]})",
			    num_zoom_level: json["Data"]["description"],
			    latlng: "POINT (#{json["Location"]["lng"]} #{json["Location"]["lat"]})",
			    elevation: json["Location"]["elevation_wgs84_m"].to_f,
			    description: json["Location"]["description"],
			    street: json["Location"]["streetRange"],
			    region: json["Location"]["region"],
			    country: json["Location"]["country"],
			    raw_json: json,
			    links: links_ids.join(","),
			    processed_at: Time.now
			  })
	end
		end
		p i
	end
end
