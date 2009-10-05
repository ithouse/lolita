namespace :lolita do
  desc "Setup lolita"
  task :setup => :environment do

    # create db if needed
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    begin
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.active?
    rescue
      puts "Creating database '#{config['database']}' ..."
      charset   = ENV['CHARSET']   || 'utf8'
      collation = ENV['COLLATION'] || 'utf8_general_ci'
      ActiveRecord::Base.establish_connection(config.merge('database' => nil))
      ActiveRecord::Base.connection.create_database(config['database'], :charset => (config['charset'] || charset), :collation => (config['collation'] || collation))
      ActiveRecord::Base.establish_connection(config)
    end

    # create schema migrations table
    unless ActiveRecord::Base.connection.respond_to?(:initialize_schema_information)
      ActiveRecord::Base.connection.initialize_schema_migrations_table
      ActiveRecord::Base.connection.assume_migrated_upto_version(0)
    end

    ENV["NAME"] = "lolita"
    Rake::Task["db:migrate:plugin"].invoke


=begin rdoc
Prompts the user to input something in the console and either returns the
string result or the result of a case-insensitive comparison of input/expected.

Accepts a string to set :title with other params default, or a hash with:
title:: the text to put for prompt
expected:: string/answer expected, defaults to "yes" which also accepts "y"
default:: the fallback string if ENTER was pressed. expected must be set to nil/false
         the default value is displayed appending "(default): " to the prompt title
=end
    def prompt(options={})
      options={:title=>options} if options.is_a?(String)
      options={:title=>'Do you want to continue?',:expected=>"yes"}.merge(options)
      print "#{options[:title]} #{options[:default]?"(#{options[:default]}): ":""}" if options[:title]
      reply=STDIN.gets().strip
      if options[:expected]
        return true if options[:expected]=="yes" && reply[0,1].downcase=="y"
        return options[:expected].downcase==reply.downcase
      end
      return options[:default] if options[:default] && reply==""
      reply
    end
    
    # Create static file link
    unless File.exists?("#{RAILS_ROOT}/public/lolita")
      #check if have drive name for RAILS_ROOT -> simple test to know if on Windows
      if RAILS_ROOT.match(/^[a-z]:[\\\/]/i)
        begin
          `linkd` #falls to rescue unless found
        rescue
          puts "It seems you don't have the linkd.exe tool needed for creation of symlinks on Windows"
          puts "The tool can be obtained through installation of the Windows Resource Kit Tools (WRKT) package."
          link="http://www.microsoft.com/Downloads/details.aspx?FamilyID=9d467a69-57ff-4ae7-96ee-b18c4790cffd&displaylang=en"
          if prompt("Would you like to download and install the WRKT now?")
            system("start #{link}")
            if !prompt("Please confirm that you installed the WRKT")
              return if !prompt("Would you still like to continue?")
            end
          else
            return if !prompt("Would you still like to continue?")
          end
        end
        begin
          #can fail if path contains non-asci chars
          system("linkd \"#{RAILS_ROOT}/public/lolita\" \"#{RAILS_ROOT}/vendor/plugins/lolita/_public/\"")
        rescue
          puts "Could not symlink \"#{RAILS_ROOT}/vendor/plugins/lolita/_public/\" to \"#{RAILS_ROOT}/public/lolita\""
          puts "Please do that manually."
        end
      else
        FileUtils.ln_s("#{RAILS_ROOT}/vendor/plugins/lolita/_public/","#{RAILS_ROOT}/public/lolita")
      end
      puts "[new] #{RAILS_ROOT}/public/lolita"
    end

    # copy lolita's YAML config file
    unless File.exists?("#{RAILS_ROOT}/config/lolita.yml")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/lolita.yml","#{RAILS_ROOT}/config/lolita.yml")
      puts "[new] config/lolita.yml"
    end

    # copy lolita's initializer
    unless File.exists?("#{RAILS_ROOT}/config/initializers/start_lolita.rb")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/initializers/start_lolita.rb","#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      puts "[new] config/initializers/start_lolita.rb"
    end

    # copy lolita's default public.js
    unless File.exists?("#{RAILS_ROOT}/public/javascripts/public.js")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/_public/javascripts/public.js","#{RAILS_ROOT}/public/javascripts/public.js")
      puts "[new] public/javascripts/public.js"
    end

    # create blank CSS file used by TinyMCE
    unless File.exists?("#{RAILS_ROOT}/public/stylesheets/tinymcestyle.css")
      File.open("#{RAILS_ROOT}/public/stylesheets/tinymcestyle.css", "w")
      puts "[new] public/stylesheets/tinymcestyle.css"
    end

    # Insert must have data into DB
    unless Admin::Role.find_by_name("administrator")
      puts
      puts "Please provide details for the Administrator account."
      puts
      puts "Press ENTER to stick to the defaults specified in brackets."
      puts "(they can be changed later in the system's backend."
      puts
      login=prompt(:title=>"Login",:expected=>nil,:default=>"admin")
      password=prompt(:title=>"Password",:expected=>nil,:default=>"admin")
      email=prompt(:title=>"E-mail",:expected=>nil,:default=>"admin@example.com")

      ActiveRecord::Base.transaction do
        role=Admin::Role.create!(:name=>'administrator', :built_in=>true)
        Admin::SystemUser.create!(
          :login=>login,
          :password=>password,:password_confirmation=>password,
          :email=>email,:roles=>[role]
        )
        menu=Admin::Menu.create!(
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
        menu_root=menu.menu_items.first.root
        first_item=Admin::MenuItem.create!(
          :name=>"Administration",
          :menu_id=>menu.id,
          :menuable_id=>0
        )
        first_item=Admin::MenuItem.first(:conditions=>["name=? AND menu_id=? AND menuable_id=?",
             'Administration',menu.id,0]) unless first_item
        first_item.move_to_child_of(menu_root)
        ["/admin/user","/admin/role","/admin/access","/admin/table"].each{|controller|
          Admin::MenuItem.create!(
            :name=>controller.split("/").last.pluralize.capitalize,
            :menu_id=>menu.id,
            :menuable=>Admin::Action.create!(:controller=>controller,:action=>"list")
          ).move_to_child_of(first_item)
        }
        
        [[3435,true],[1819,false],[5556,false]].each{|language|
          Admin::Language.create!(:globalize_languages_id=>language.first,:is_base_locale=>language.last)
        }
      end
    end

    puts "Migrating other plugins..."
    Rake::Task["db:migrate:all"].invoke

    puts "Setup globalize..."
    Rake::Task["globalize:setup"].invoke

    puts "Setup has finished, now you can run test server 'ruby script/server' and open http://localhost:3000/system/login"
  end
end