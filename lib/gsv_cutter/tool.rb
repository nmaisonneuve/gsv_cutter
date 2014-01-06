class Tool

	class Batch
		
		def initialize()
			@cmds = []
			@width= 1200
    	@height = 900    	
    	@steep_angle = 0.0
    	@pitch_deg = 0.0
		end

		def add(filename, side, pov, pitch_deg = @pitch_deg, force = false)
		  output_path = filename.gsub("zoom_#{Pano::ZOOM}","zoom_#{Pano::ZOOM}_side_#{side}_pov_#{pov}_pitch_#{@pitch_deg}")
  		unless (File.exists?(output_path))
  			puts "\n\n\nERORORORORORORORO\n\n\n"  unless File.exists?(filename)
				@cmds << generate(filename, side, pov, pitch_deg, output_path)
			else
    		puts "projected GSV image alread existing.."
 			end
 			output_path
		end

		def run
			i = 0
			batch_size = 30
			num = @cmds.size / batch_size

			puts " #{@cmds.size } cut in #{num} batches"
			# compute batches
			batches = []
			@cmds.each_slice(batch_size) do |batch|
				batches << batch
			end
			
		
			Parallel.map(batches,:in_threads=>3) do |batch|
				puts "projecting #{batch.size} images.."
				p batch[0]
				unless batch.empty?
					cmd = "/Applications2/MATLAB_R2012a.app/bin/matlab -nosplash -nodesktop -r \"addpath('/Users/maisonne/Documents/work/gsv_cutter/');addpath('/Users/maisonne/Documents/work/gsv_cutter/matlab/');"
					cmd += batch.shuffle.join("")
					cmd += "quit;\""
					#p cmd
		      Subexec.run cmd, :timeout => 0 
	    	else
	    		puts "batch empty"
	    	end
    	end
		end

		def generate(input, side, pov, pitch_deg, output)
			"cut_image('~/Documents/work/gsv_cutter/#{input}', #{side.to_f}, #{pov.to_f},#{pitch_deg}, #{@steep_angle.to_f}, #{@height}, #{@width},'~/Documents/work/gsv_cutter/#{output}');"
    end
	end

	def initialize(filename, deg_start, deg_end)
		raise Exception.new("file #{filename} not found") unless File.exists?(filename)
		@deg_start = deg_start.to_f
		@deg_end = deg_end.to_f
		@filename = filename
		img = JPEG.new(filename)
		@width = img.width.to_f
		@height = img.height.to_f 
		@ground_level = 500		
	end

	def ratio_deg(angle)
		(angle - @deg_start) / (@deg_end - @deg_start)
	end

	def mark_angle(angle, color = "red")
		ratio = ratio_deg(angle)
		pixel =  ratio * @width
		puts "mark #{angle} / #{ratio} / #{@width} /#{pixel}"
		mark_pixel(pixel, color)
	end

	def mark_pixel(pixel, color = "white")
	  # cmd = "convert #{filename}  -crop #{width}x#{1664.to_i}+#{start}+0  building_cut.jpg"
	 	cmd = " convert #{@filename}  -fill none -stroke #{color} -strokewidth 3 -draw 'line #{pixel},0 #{pixel},2664' #{@filename}"
	 	# p cmd
    Subexec.run cmd, :timeout => 0
	end

	def cut_angles(deg1, deg2, output_path)
		puts "cut angles (#{deg1}, #{deg2})"
		p1 = ratio_deg(deg1) * @width
		p2 = ratio_deg(deg2) * @width
		cut_pixels(p1, p2, output_path)
	end

  def cut_pixels(pixel1, pixel2, output_path)
	  width = pixel2 - pixel1
	  start = pixel1
	  puts "#{pixel1} - #{pixel2}"
	  #ground_pixel = 150
	  if (width < 0)
	  	start = pixel2
	  	width = - width
	  end
	   cmd = "convert #{@filename}  -crop #{width.to_i}x#{(@height - @ground_level).to_i}+#{start.to_i}+0  #{output_path}"
	 	#cmd = " convert #{@filename}  -fill none -stroke white -draw 'line #{start},0 #{start},1664'  #{@filename}"
	 	p cmd
    Subexec.run cmd, :timeout => 0
	end

	#   def cutting_from_pixels(pixel1, pixel2)
	#   width = pixel2 - pixel1
	#   start = pixel1
	#   if (width < 0)
	#   	start = pixel2
	#   	width = - width
	#   end
	#   cmd = "convert #{panoID}_zoom_4.jpg  -crop #{width}x#{HEIGHT.to_i}+#{start}+0  building-#{panoID}_cut.jpg"
	#  	p cmd
 #    Subexec.run cmd, :timeout => 0
	# end

 #  def cutting_from_angles(angle1, angle2)
 #  	pixel1 = angle_to_pixel(angle1)
 #    puts "transform #{angle1} to #{pixel1}"

 #  	pixel2 = angle_to_pixel(angle2)
	# 	puts "transform #{angle2} to #{pixel2}"
    
 #    cutting_from_pixels(pixel1, pixel2)
 #  end

 #  # convert to an angle from map to the point of view of a panorama
 #  # the center of the pov has an angle of 0, left <0, right > 0 
 #  # examples of output:
 #  def to_pov_angle(angle)
 #    relative_angle  = (angle - yaw_deg)
 #    if (relative_angle.abs> 180)
 #      relative_angle = (relative_angle > 0)? relative_angle - 360: relative_angle + 360
 #    end
 #    relative_angle
 #  end

 #  def from_pov_angle(angle)
 #    absolute_angle  = ((yaw_deg + angle) + 360) % 360
 #  end


 #  # angle from [-180 to 180]
 #  # 0 to 260
 #  def pixel_to_angle(pixel)

 #    pixel_center = WIDTH.to_f/2.0

 #    relative_pixel = pixel - pixel_center

 #    relative_angle = relative_pixel * pixel_center / 180.0

 #    absolute_angle = ((360.0 - YAWDEG + relative_angle) % 360)

 #    absolute_angle
 #  end

 #  # angle from [-180 to 180]
 #  # 0 to 360
 #  def angle_to_pixel(angle)
 #    relative_angle = to_pov_angle(angle)
 #    center_angle = 180
 #    ratio = (center_angle + relative_angle)/ 360.0
 #  	(WIDTH * ratio).to_i
 #  end

end