namespace :lolita do
  desc "Setups Lolita for your rails project"
  task :setup do
    #TODO: setup lolita
  end
end

#namespace :db do
#  namespace :migrate do
#    description = "Migrate the database through Lolita's migrations"
#    description << "and update db/schema.rb by invoking db:schema:dump."
#    description << "Target specific version with VERSION=x. Turn off output with VERBOSE=false."
#    desc description
#    task :lolita => :environment do
#      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
#      ActiveRecord::Migrator.migrate("vendor/plugins/lolitadb/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
#      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
#    end
#  end
#end
