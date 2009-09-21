namespace :lolita do
  desc "Setup lolita"
  task :setup => :environment do
    # Create static file link
    unless File.exists?("#{RAILS_ROOT}/public/lolita")
      FileUtils.ln_s("#{RAILS_ROOT}/vendor/plugins/lolita/_public/","#{RAILS_ROOT}/public/lolita")
      puts "[new] #{RAILS_ROOT}/public/lolita"
    end

    # copy lolita's YAML config file
    unless File.exists?("#{RAILS_ROOT}/config/lolita.yml")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/lolita.yml","#{RAILS_ROOT}/config/lolita.yml")
      puts "[new] config/lolita.yml"
    end

    # copy lolita's initializer
    unless File.exists?("#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/initializers/lolita_init.rb","#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      puts "[new] config/initializers/lolita_init.rb"
    end

    # create blank CSS file used by TinyMCE
    unless File.exists?("#{RAILS_ROOT}/public/stylesheets/tinymcestyle.css")
      File.open("#{RAILS_ROOT}/public/stylesheets/tinymcestyle.css", "w")
      puts "[new] public/stylesheets/tinymcestyle.css"
    end

    # Insert must have data into DB
    unless Admin::Role.find_by_name("administrator")
      ActiveRecord::Base.transaction do
        role=Admin::Role.create!(:name=>'administrator', :built_in=>true)
        Admin::SystemUser.create!(
          :login=>'admin',:email=>'admin@example.com',
          :password=>'admin',:password_confirmation=>'admin',
          :roles=>[role]
        )
        Admin::Menu.create!(
          :menu_name=>'Admin',
          :menu_type=>'app',
          :module_name=>'admin',
          :module_type=>'app'
        )
        Admin::Menu.create!(
          :menu_name=>'Content',
          :menu_type=>'web',
          :module_name=>'admin',
          :module_type=>'web'
        )
        ["/admin/user","/admin/role","/admin/access","/admin/table"].each{|controller|
          Admin::Action.create!(:controller=>controller,:action=>"list")
        }
        [[3435,true],[1819,false],[5556,false]].each{|language|
          Admin::Language.create!(:globalize_languages_id=>language.first,:is_base_locale=>language.last)
        }
      end
    end
  end
end