namespace :lolita do
  desc "Sync Lolita's static files images/js ..."
  task :sync do
    system "rsync -ruv vendor/plugins/lolita/public/lolita public/."

    # YAML config file
    unless File.exists?("#{RAILS_ROOT}/config/lolita.yml")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/lolita.yml","#{RAILS_ROOT}/config/lolita.yml")
      puts "[new] config/lolita.yml"
    end

    # initializer
    unless File.exists?("#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/initializers/lolita_init.rb","#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      puts "[new] config/initializers/lolita_init.rb"
    end
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
