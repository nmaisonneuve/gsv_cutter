# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130607104358) do

  create_table "building_povs", :id => false, :force => true do |t|
    t.integer "pano_id"
    t.integer "building_id"
    t.float   "min_degree"
    t.spatial "min_ray",     :limit => {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.float   "max_degree"
    t.spatial "max_ray",     :limit => {:srid=>4326, :type=>"geometry", :geographic=>true}
  end

  create_table "buildings", :primary_key => "gid", :force => true do |t|
    t.integer "n_sq_eb"
    t.string  "b_igh",      :limit => 1
    t.string  "b_er",       :limit => 1
    t.string  "b_ee",       :limit => 1
    t.integer "an_const"
    t.integer "an_rehab"
    t.integer "an_rehabf"
    t.integer "c_perconst", :limit => 2
    t.string  "b_dalle",    :limit => 1
    t.string  "b_horspu",   :limit => 1
    t.decimal "h_moy"
    t.decimal "h_med"
    t.decimal "h_min"
    t.decimal "h_max"
    t.integer "h_ecart"
    t.decimal "m2_zinc"
    t.decimal "m2_tuile"
    t.decimal "m2_terrveg"
    t.decimal "m2_ardoise"
    t.decimal "m2_beton"
    t.integer "c_toitdom",  :limit => 2
    t.integer "n_sq_ar"
    t.integer "n_sq_pc"
    t.integer "n_sq_pu"
    t.decimal "shape_leng"
    t.decimal "shape_area"
    t.string  "d_b_igh",    :limit => 254
    t.string  "d_b_er",     :limit => 254
    t.string  "d_b_ee",     :limit => 254
    t.string  "d_c_percon", :limit => 254
    t.string  "d_b_dalle",  :limit => 254
    t.string  "d_b_horspu", :limit => 254
    t.string  "d_c_toitdo", :limit => 254
    t.spatial "geom",       :limit => {:srid=>4326, :type=>"multi_polygon"}
  end

  add_index "buildings", ["geom"], :name => "city_geom_gist", :spatial => true

  create_table "detections", :force => true do |t|
    t.float   "left_angle"
    t.float   "right_angle"
    t.integer "detector_id"
    t.integer "pano_id"
    t.integer "building_id"
    t.integer "facade_id"
    t.spatial "geom",        :limit => {:srid=>4326, :type=>"line_string", :geographic=>true}
    t.integer "state"
  end

  add_index "detections", ["geom"], :name => "index_detections_on_geom", :spatial => true

  create_table "exterior9", :id => false, :force => true do |t|
    t.integer "gid"
    t.spatial "st_intersection", :limit => {:srid=>0, :type=>"geometry"}
  end

  add_index "exterior9", ["gid"], :name => "primary_key"

  create_table "facades", :force => true do |t|
    t.integer "building_id"
    t.spatial "geom",        :limit => {:srid=>4326, :type=>"geometry", :geographic=>true}
  end

  add_index "facades", ["geom"], :name => "index_facades_on_geom", :spatial => true

  create_table "panos", :force => true do |t|
    t.spatial  "latlng",          :limit => {:srid=>4326, :type=>"point", :geographic=>true}
    t.string   "panoID",                                                                                         :null => false
    t.float    "yaw_deg"
    t.datetime "created_at",                                                                                     :null => false
    t.datetime "updated_at",                                                                                     :null => false
    t.boolean  "selected",                                                                    :default => false
    t.spatial  "original_latlng", :limit => {:srid=>4326, :type=>"point", :geographic=>true}
    t.date     "image_date"
    t.float    "elevation"
    t.string   "description"
    t.string   "street"
    t.string   "region"
    t.string   "country"
    t.text     "raw_json"
    t.datetime "processed_at"
    t.string   "links"
    t.integer  "num_zoom_level"
    t.string   "filepath"
    t.integer  "label"
  end

  add_index "panos", ["latlng"], :name => "index_panos_on_latlng", :spatial => true
  add_index "panos", ["original_latlng"], :name => "index_panos_on_original_latlng", :spatial => true
  add_index "panos", ["panoID"], :name => "index_panos_on_panoID", :unique => true

  create_table "pov_buildings", :id => false, :force => true do |t|
    t.spatial "scope",       :limit => {:srid=>0, :type=>"geometry"}
    t.integer "pano_id"
    t.integer "ray_id"
    t.integer "segment_id"
    t.integer "building_id"
    t.spatial "inter_point", :limit => {:srid=>0, :type=>"geometry"}
    t.float   "distance"
    t.float   "raw_angle1"
    t.float   "raw_angle2"
    t.float   "rel_angle1"
    t.float   "rel_angle2"
  end

  create_table "rays", :force => true do |t|
    t.integer "pano_id"
    t.spatial "geom",         :limit => {:srid=>4326, :type=>"line_string", :geographic=>true}
    t.float   "angle"
    t.integer "detection_id"
  end

  add_index "rays", ["geom"], :name => "index_rays_on_geom", :spatial => true

  create_table "segments", :primary_key => "gid", :force => true do |t|
    t.spatial "geom",        :limit => {:srid=>0, :type=>"geometry"}
    t.integer "building_id"
  end

  add_index "segments", ["geom"], :name => "segments_geom_gist", :spatial => true

  create_table "test1", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.spatial "point",     :limit => {:srid=>0, :type=>"geometry"}
  end

  create_table "test2", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.boolean "point"
  end

  create_table "test3", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.boolean "point"
  end

  create_table "test4", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.boolean "point"
  end

  create_table "test5", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.spatial "point",     :limit => {:srid=>0, :type=>"geometry"}
  end

  create_table "test6", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.spatial "point",     :limit => {:srid=>0, :type=>"geometry"}
  end

  create_table "test7", :id => false, :force => true do |t|
    t.integer "ray_id"
    t.integer "facade_id"
    t.spatial "point",     :limit => {:srid=>0, :type=>"geometry"}
  end

  create_table "tmp", :force => true do |t|
    t.spatial "geom", :limit => {:srid=>0, :type=>"polygon"}
  end

  add_index "tmp", ["geom"], :name => "sidx_test_5arrondissement_geom", :spatial => true

  create_table "visibility_feature_talbe", :id => false, :force => true do |t|
    t.integer "pano_id"
    t.spatial "latlng",     :limit => {:srid=>4326, :type=>"point", :geographic=>true}
    t.float   "visibility"
  end

  create_table "visible_rays", :force => true do |t|
    t.integer "ray_id",      :limit => 8
    t.integer "pano_id",     :limit => 8
    t.integer "facade_id",   :limit => 8
    t.integer "building_id", :limit => 8
    t.spatial "point",       :limit => {:srid=>4326, :type=>"point", :geographic=>true}
    t.float   "distance"
  end

  add_index "visible_rays", ["point"], :name => "v_rays_geom_gist", :spatial => true
  add_index "visible_rays", ["ray_id"], :name => "v_rays_on_ray_id"

  create_table "visible_scope_v2", :id => false, :force => true do |t|
    t.integer "pano_id"
    t.integer "building_id"
    t.spatial "scope",       :limit => {:srid=>0, :type=>"geometry"}
  end

  create_table "visible_scope_v3", :id => false, :force => true do |t|
    t.integer "pano_id"
    t.integer "building_id"
    t.spatial "scope",       :limit => {:srid=>0, :type=>"geometry"}
  end

end
