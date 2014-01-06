require 'gsv_downloader'
require 'net/http'

class Pano < ActiveRecord::Base

  #set_rgeo_factory_for_column(:latlng, RGeo::Geos.factory(srid: 4326))

  attr_accessible :panoID, :image_date, :yaw_deg, :original_latlng, 
  :latlng, :elevation, :description, 
  :street, :region, :country, :raw_json, 
  :links, :processed_at,
  :num_zoom_level, 
  :selected, 
  :label,
  :steep_angle,
  :direction

  has_many :rays
  has_many :visible_rays
  has_many :povs
  has_many :panosFacades

  RAD2DEG = 180.0 / Math::PI
  DEG2RAD = Math::PI / 180.0
  
  ZOOM = 3
  # image width x height
  WIDTH = 416 * 2**(ZOOM)
	HEIGHT = 416 * 2**(ZOOM - 1)

  def lat
  	latlng.y
  end

  def lng
  	latlng.x
  end

  def generate_postgis(relative_angle, distance_meter)
    absolute_angle = (( yaw_deg + relative_angle) % 360) * DEG2RAD #
    lat1 =  DEG2RAD * lat
    lng1 =  DEG2RAD * lng
    d_rad = distance_meter.to_f / 6378137.0
    lat2 = Math::asin(Math::sin(lat1) * Math::cos(d_rad) + Math::cos(lat1)* Math::sin(d_rad)* Math::cos(absolute_angle))
    lng2  = lng1 + Math::atan2(Math::sin(absolute_angle) * Math::sin(d_rad) * Math::cos(lat1), Math::cos(d_rad) - Math::sin(lat1) * Math::sin(lat2))
    end_point = [lng2 * RAD2DEG, lat2 * RAD2DEG]
    # LINESTRING (Lon Lat)
     "LINESTRING(#{lng} #{lat}, #{end_point[0]} #{end_point[1]} )"
   
  end
  def generate_ray(relative_angle, distance_meter, type)
    geom_string = generate_postgis(relative_angle, distance_meter)
    self.rays << Ray.new(angle: relative_angle, geom: geom_string, pano_id:self.id, type: type )
    self.rays
  end


  def project(angle, pov = 90, output_path)
    # output_path = filename.gsub("zoom_#{ZOOM}","zoom_#{ZOOM}_angle_#{angle}_pov_#{pov}"
    altitude_angle = 0
    steep_angle = 0
    width= 1600
    height = 2500
    unless File.exists?(output_path)
      cmd = "/Applications2/MATLAB_R2012a.app/bin/matlab -nosplash -nodesktop -r \"addpath('/Users/maisonne/Documents/work/gsv_cutter/');addpath('/Users/maisonne/Documents/work/gsv_cutter/matlab/');cut_image('#{filename}', #{angle.to_f}, #{pov.to_f}, #{steep_angle.to_f}, #{height}, #{width},'#{output_path}');quit;\""
      p cmd
      Subexec.run cmd, :timeout => 0
    else
      puts "projected GSV image alread existing.."
    end
    output_path
  end

  def get_default_zoom
    3
  end

  def filename(zoom = ZOOM)
    self.panoID+"_zoom_#{zoom}.jpg"
  end

  def file_width
    JPEG.new(filename).width
  end

  def to_download?
    !File.exists?(filename)
  end

  def check_valid
    url =  "https://geo3.ggpht.com/cbk?output=json&cb_client=maps_sv&fover=2&onerr=3&renderer=spherical&v=4&panoid=#{panoID}"
    result = Net::HTTP.get(URI.parse(url))
    result.size > 10
  end

  def side_image(side, pov_deg, side_image_path)
    # side_image_path = filename.gsub("zoom_#{ZOOM}","zoom_#{ZOOM}_angle_#{side}")
    # self.project(side, pov_deg, side_image_path)
    start_angle = side - (pov_deg/2.0)
    end_angle = side + (pov_deg/2.0)
    Tool.new(side_image_path , start_angle, end_angle)
  end

def cut_angle(start_angle, end_angle, output_image_path)
    # side_image_path = filename.gsub("zoom_#{ZOOM}","zoom_#{ZOOM}_angle_#{side}")
    # self.project(side, pov_deg, side_image_path)
    tool = Tool.new(filename, -180.0, 180.0)
    tool.cut_angles(start_angle, end_angle, output_image_path)
  end

  def mark_angle(angle)
    download() if to_download?
    @tool = Tool.new(filename, -180.0, 180.0)
    @tool.mark_angle(angle)
  end

  def download(dir = ".", zoom = ZOOM)
    puts "downloading GSV image #{panoID} to #{dir} "
    begin
      downloader = ImageDownloaderParallel.new
      downloader.download(self.panoID, zoom, dir)
      return true
    rescue Exception => e
      puts "error dowloading pano #{e.message}"
      return false
    end
  end
end