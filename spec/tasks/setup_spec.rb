require 'rubygems'
require 'spec'
require 'fileutils'

def gsub_file(path, regexp, *args, &block)
  content = File.read(path).gsub(regexp, *args, &block)
  File.open(path, 'wb') { |file| file.write(content) }
end

describe "Setup" do
  it "should run 'rake lolita:setup' successfully on blank rails project" do
    root_dir = File.expand_path "#{File.dirname(__FILE__)}/../../"
    test_dir = File.join(root_dir,".tmp")
    FileUtils.rm_rf(test_dir) if File.exists?(test_dir)
    FileUtils.mkdir(test_dir)
    FileUtils.cd(test_dir)
    system "rails -q -d sqlite3 test_app"
    rails_dir = File.join(test_dir,"test_app")
    File.exists?(rails_dir).should be_true
    FileUtils.cd(rails_dir)
    lolita_files = Dir.glob("#{root_dir}/*")
    FileUtils.mkdir(File.join(rails_dir,'vendor/plugins/lolita'))
    FileUtils.cp_r(lolita_files,File.join(rails_dir,'vendor/plugins/lolita'))
    system "ruby script/plugin install git://github.com/ithouse/lolita_engines.git"

    # patch environment.rb
    line = 'Rails::Initializer.run do |config|'
    gsub_file File.join(rails_dir,'config/environment.rb'), /(#{Regexp.escape(line)})/mi do
    |match|
      %^
require File.join(File.dirname(__FILE__), '../vendor/plugins/lolita_engines/boot')

#{match}

  config.plugins = [ :lolita_engines, :lolita, :all ]
  config.plugin_paths += ["\#{RAILS_ROOT}/vendor/plugins/lolita/plugins"]
  config.i18n.default_locale = :en
  config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')]
  config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'vendor', 'plugins', 'lolita', 'config', 'locales', '**', '*.{rb,yml}')]
  config.gem "factory_girl"
      ^
    end


    system "rake lolita:setup RAILS_ENV=test"
    # ---
    FileUtils.rm_rf(test_dir)
  end
end