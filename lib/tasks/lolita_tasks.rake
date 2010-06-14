require 'spec/rake/spectask'

namespace :lolita do
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
    return options[:default] if RAILS_ENV == 'test' && options[:default]
    options={:title=>options} if options.is_a?(String)
    options={:title=>'Do you want to continue?',:expected=>"yes"}.merge(options)
    print "#{options[:title]} #{options[:default]?"(#{options[:default]}): ":""}" if options[:title]
    $stdout.flush
    reply=STDIN.gets().strip
    if options[:expected]
      return true if options[:expected]=="yes" && reply[0,1].downcase=="y"
      return options[:expected].downcase==reply.downcase
    end
    return options[:default] if options[:default] && reply==""
    reply
  end

  desc "Run Lolita's migrations"
  task :migrate do
    init_db_schema
    ENV["NAME"] = "lolita"
    Rake::Task["db:migrate:plugin"].invoke
  end

  desc "Link static files"
  task :link_static_files => :environment do
    unless File.exists?("#{RAILS_ROOT}/public/lolita")
      #check if have drive name for RAILS_ROOT -> simple test to know if on Windows
      if RAILS_ROOT.match(/^[a-z]:[\\\/]/i)
        linkd="linkd \"#{RAILS_ROOT}/public/lolita\" \"#{RAILS_ROOT}/vendor/plugins/lolita/_public/\""
        unless system(linkd)
          puts "\n\nIt seems you don't have the linkd.exe tool needed for creation of symlinks on Windows"
          puts "The tool can be obtained through installation of the Windows Resource Kit Tools (WRKT) package."
          puts ""
          puts "*** You may also get this warning if running Git Bash,"
          puts "    which may not have access to the MSDOS utilities."
          puts "    You should still continue and receive instruction to create the symlink manually."
          puts ""
          link="http://www.microsoft.com/Downloads/details.aspx?FamilyID=9d467a69-57ff-4ae7-96ee-b18c4790cffd"
          if prompt("Would you like to download and install the WRKT now? (y/n)")
            system("start #{link}")
            if !prompt("Please confirm that you installed the WRKT (y/n)")
              return if !prompt("Would you still like to continue? (y/n)")
            end
          else
            return if !prompt("Would you still like to continue? (y/n)")
          end
          #can fail if path contains non-asci chars
          unless system(linkd)
            bat="#{RAILS_ROOT}/tmp/linkup.bat"
            File.open(bat, 'w') {|f| f.write("#{linkd}\npause") }
            puts "\nCould not symlink Lolita's JavaScript folder"
            puts "Please do it manually by running:\n #{linkd}\n"
            puts "(The command has been written to '#{bat}' for your convenience)\n\n\n"
          end
        end
      else
        FileUtils.ln_s("#{RAILS_ROOT}/vendor/plugins/lolita/_public/","#{RAILS_ROOT}/public/lolita")
      end
      puts "[new] #{RAILS_ROOT}/public/lolita"
    end
  end

  desc "Generate Lolita's specific files"
  task :generate => [:environment,:link_static_files] do
    #TODO: destroy should work to
    require 'rails_generator'
  	require 'rails_generator/scripts/generate'
    #require 'rails_generator/scripts/destroy'
    #unless ARGV[0] == "destroy"
    Rails::Generator::Scripts::Generate.new.run(ARGV, :generator => "lolita")
    #else
    #  Rails::Generator::Scripts::Destroy.new.run("lolita")
    #end
  end

  desc "Setup Lolita"
  task :setup => [:environment, :migrate, :generate] do

    #INFO: workaround, before environment is loaded this task is invisible - rails 2.3.8 bug
    load File.join(RAILS_ROOT,'vendor/plugins/lolita/plugins/globalize_extension/lib/tasks/data.rake')
    Rake::Task["globalize:setup"].invoke

    # Insert must have data into DB
    unless Admin::Role.find_by_name("administrator")
      puts
      puts "Please provide details for the Administrator account."
      puts
      puts "Press ENTER to stick to the defaults specified in brackets."
      puts "(they can be changed later in the system's backend."
      puts
      $stdout.flush
      login=prompt(:title=>"Login",:expected=>nil,:default=>"admin")
      password=prompt(:title=>"Password",:expected=>nil,:default=>"admin")
      email=prompt(:title=>"E-mail",:expected=>nil,:default=>"admin@example.com")

      ActiveRecord::Base.transaction do
        role=Admin::Role.create!(:name=>'administrator', :built_in=>true)
        Admin::SystemUser.create!(
          :login=>login,
          :password=>password,
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
        if trans=Admin::Menu.insert("Admin", :last, "Translations", "/admin/locale/index")
          trans.move_to_child_of(first_item)
        end
        [[3435,true],[1819,false],[5556,false]].each{|language|
          Admin::Language.create!(:globalize_languages_id=>language.first,:is_base_locale=>language.last)
        }
      end
    end

    puts "Migrating other plugins..."
    Rake::Task["db:migrate:all"].invoke

    puts "Setup has finished, now you can run test server 'ruby script/server' and open http://localhost:3000/system/login"
  end

  # Runs lolita's rspec tests
  desc "Run RSpec tests"
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_files = FileList["#{File.dirname(__FILE__)}/../spec/**/*_spec.rb"]
    t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/../spec/spec.opts\""]
  end

  namespace :locales do
    desc "Merge YAML locale files"
    task :merge => :environment do
      $stdout.flush
      if prompt("Are you shore to merge locales? (y/n)")
        merger = Lolita::LocaleMerger.new
        merger.merge
        puts "[done]"
      end
    end

    desc "Show status of YAML locale files"
    task :status => :environment do
      $stdout.flush
      merger = Lolita::LocaleMerger.new
      puts merger.status_report
    end

    desc "Clones locale from one to another locale"
    task :clone => :environment do
      $stdout.flush
      from = prompt(:title=>"Clone from: (#{I18n.available_locales.join("/")})",:expected=>nil)
      to   = prompt(:title=>"Clone to:",:expected=>nil)
      unless (I18n.available_locales.include?(from.to_sym) && to =~ /^[A-Za-z\-]+$/)
        puts "[error] Invalid input languages"
      else
        merger = Lolita::LocaleMerger.new
        merger.clone from, to
        puts "[done]"
      end
    end
  
  end

  # Initialize database schema information table
  def init_db_schema
    unless ActiveRecord::Base.connection.respond_to?(:initialize_schema_information)
      ActiveRecord::Base.connection.initialize_schema_migrations_table
      ActiveRecord::Base.connection.assume_migrated_upto_version(0)
    end
  end

end
