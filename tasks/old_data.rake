namespace :old_data do

	desc "transfert"
	task :bug => ["standalone:connection"]   do
	require 'set'
		# parsing the download file to collect the panoIDs
		i = 0
		panoIDs = Set.new
		File.open("data/download.txt").each_with_index do |line|
			panoIDs << line[0..21]
			i +=1
		end
		puts "Petr Database (#{i} panoramas) loaded"
		Pano.all.each_with_index do | pano, i |
			unless panoIDs.include?(pano.panoID)
				pano.update_attributes(selected: true)
				puts "#{pano.panoID}: #{pano.description}"
			end
		end
	end

	desc "transfert"
	task :import => ["standalone:connection"]   do
		require 'csv'

		# parsing the download file to collect the panoIDs
		i = 0

		File.open("data/download.txt").each_with_index do |line|
			panoIDs[i] = line[0..21]
			i +=1
		end

		# parsing the mapping file to collect the lat,lng, paw
		reg = /(\d+) ([\d|\.]+) -4 ([\d|\.]+)_([\d|\.]+)/
		j = 0
		i = 0

		# CSV.open("data/paris.csv","wb") do | csv|
		File.open("data/mapping.txt").each do |line|
			if ((i % 14) ==0)
				matched = reg.match(line)
				pov = matched[2].to_f
				lat = matched[3]
				lng = matched[4]
				panoID = panoIDs[j]
				pano = Pano.create(panoID: panoID, photographerPOV: pov, latlng: "POINT (#{lng} #{lat})")
			# 	csv << [panoID, lat, lng, pov]
				j += 1
			end
			i += 1
		end
	end
end
