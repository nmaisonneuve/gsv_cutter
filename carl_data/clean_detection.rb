require 'set'
require 'csv'
i = 0

# parsing the download file to collect the panoIDs
panoIDs = {}
File.open("../data/download.txt").each_with_index do |line|
	match = line.match(/\((.*), (.*)\)/)
	file_prefix = "#{sprintf( "%0.06f", match[1].to_f.abs)}_#{sprintf( "%0.06f",match[2].to_f.abs)}"
	panoID = line[0..21]
	#puts "#{file_prefix} => #{panoIDs}"
	panoIDs[file_prefix] = panoID
	i += 1
end

	puts " #{panoIDs.size} GSV panoramas used (download.txt)"
		images = {}
		valid_image_idx = Set.new
		panoIDs_v2 = Set.new
		i = 1
		File.open("../data/detections/imgs.csv").each_with_index do |line|
			matching = line.match(/paris\/(((.*)_(.*))_(.*)_(.*))/)
			unless matching.nil?
				valid_image_idx << i
				file_prefix = matching[2]
				panoID = panoIDs[file_prefix]
				if panoID.nil?
					puts "ERROR - #{file_prefix}"
				end
				angle = matching[5]
				images[i] = {idx: i, filename: matching[1], pano: panoID, side: angle}
				panoIDs_v2 << panoID
			end
			i += 1
		end

		puts "#{images.keys.size} side images used from #{panoIDs_v2.size} GSV panoramic images"

		# detection id to keep
		valid_detections = Set.new
		File.open("../data/detections/tokeep.csv").each_with_index do |line|
			valid_detections << line.to_i
		end

		i = 0

		valid_panos = Set.new
		valid_detectors = Set.new
		invalid_panos = Set.new
		in_paris = 0
		obsolete_detection = 0
			output = []
			CSV.foreach("../data/detections/detections.csv") do |row|

				# in paris ?
				if valid_image_idx.include?(row[6].to_i)

					in_paris += 1

					# after de-duplication
					if valid_detections.include?(row[5].to_i)

						score = row[4].to_f
						# score > 0
						# if score > 0
						image_info = images[row[6].to_i]
						i += 1
						unless Pano.find_by_panoID(image_info[:pano]).nil?
							valid_panos << image_info[:pano]
							valid_detectors << row[5]
							angle = image_info[:side]
							row = [
								row[0].to_i,
								row[1].to_i,
								row[2].to_i,
								row[3].to_i,
								score,
								row[5].to_i,
								image_info[:pano],
								angle,
								image_info[:filename]
							]
							output << row
						else
							obsolete_detection += 1
							# invalid detection (score too low)
							invalid_panos << image_info[:pano]
							#puts "invalid panos #{image_info[:pano]}"
						end
					#	end
					end
				end
			#end
		end
		puts "#{obsolete_detection} obsolete detection"
		puts " sorting"
		output.sort! {|row1,row2|
			if row1[5] == row2[5]
				row2[4]<=> row1[4]
			else
				row1[5] <=> row2[5]
			end
		}

		puts " writing csv"

		CSV.open("../data/detections/valid_detections.csv", "wb") do |csv|
			output.each do | row|
				csv << row
			end
		end

		puts "#{in_paris} detections inside Paris"
		# puts "#{i} valid detections (>0 + deduplication)"
		# puts "#{obsolete_detection} detections with obsolete panorama (not reachable anymore)"
		# puts "#{invalid_panos.size} invalid vs #{valid_panos.size} valid panorama images"
		# puts "#{valid_detectors.size} valid detectors/paths"
		#  CSV.open("./data/detections/pano_found.csv", "wb") do |csv|
		#  Pano.update_all("selected = false")
		#  Pano.transaction do
		# 	 valid_panos.each do |panoID|
		# 				#p angle.to_i
		# 			pano = Pano.find_by_panoID(panoID)
		# 			pano.selected = true
		# 			pano.save

		# 			unless pano.nil?
		# 				csv << [panoID]
		# 			end
		# 		end
		# end
		#  end
	end