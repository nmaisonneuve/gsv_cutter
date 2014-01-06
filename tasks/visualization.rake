desc "temporal_classification"
	task :visualisation => ["standalone:connection"] do
		
		period_idxs = [1,2,3,5,6,7,8,9,10,11,99]

		html = "<html lang='en'><body><h2> 1 row = 1 cluster , 1 column = 1 period of time, <br/>1 cell = 4 samples from a given cluter and at a given period of time</h2><table><thead><tr>
		<th> before 1800 </th>
		<th> 1801 - 1850 </th>
		<th> 1915 - 1939 </th>
		<th> 1940 - 1967 </th>
		<th> 1968 - 1975 </th>
		<th> 1976 - 1981 </th>
		<th> 1976 - 1981 </th>
		<th> 1982 - 1989 </th>
		<th> 1990 - 1999 </th>
		<th> 2000 and after </th>
		<th> unknown </th>
		</tr></thead>"

		Dir.glob("../data/detections/cutout_images/elements/*").each { | detector_id|
			detector_id  = detector_id.gsub("../data/detections/cutout_images/elements/","")
			period = {}
			ImprovedDetection.where(detector_id: detector_id.to_i).each { |detection|
				pc = detection.period_construction
				
				period[pc] = [] if period[pc].nil?
				period[pc] << detection
			}
			
			html << "<tr>"
			period_idxs.each { |period_idx|
				i = 0
				html <<"<td >"
				unless  period[period_idx].nil? 

					period[period_idx].each { |detection| 
					filename = detection.filename.gsub("/cutout_images/","/cutout_images/elements/")+".jpg"
					url = filename.gsub("/Users/maisonne/Documents/work/data/detections/cutout_images/","./cutout_images/")

					#	p filename
					if File.exists?(filename)
						html << "<img src='#{url}' width='70' height='70' title='period #{period_idx}'/>"	
						i = i + 1 
					end
					break if i >4
				}
				end
				html <<"</td>"
			}
			html << "</tr>"
		}
		html << "</table></body></html>"
	#	p html
		File.write("../data/detections/temporal_table.html", html)
	
	end