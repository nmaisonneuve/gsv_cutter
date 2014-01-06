require "bundler/gem_tasks"
require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks
require "./lib/gsv_cutter.rb"

namespace :db do
	task :init do
		dbconfig = YAML::load(File.open('db/config.yml'))
		ActiveRecord::Base.establish_connection(dbconfig)
	end
end

Dir.glob('tasks/*.rake').each { |r| import r }