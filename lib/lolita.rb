require 'lolita/version'

module Lolita

  CONFIGURATIONS = {}
  DEFAULT_CONFIGURATION_NAME = :default

  def self.configuration name = nil
    name ||= DEFAULT_CONFIGURATION_NAME
    CONFIGURATIONS[name] ||= Lolita::SystemConfiguration::Base.new(name)
    CONFIGURATIONS[name]
  end

  def self.setup
    self.run(:before_setup)
    yield configuration
    self.run(:after_setup)
  end
  
  def self.root
    @@root||=File.expand_path("#{__FILE__}/../..")
  end

  def self.app_root
    @@app_root||=File.join(File.expand_path("#{__FILE__}/../.."),"app")
  end
  
  def self.method_missing method_name, *args, &block
    self.class_eval <<-LOLITA_SETUP,__FILE__,__LINE__+1
      class << self
        def #{method_name}(*args,&block)
          configuration.send(:#{method_name},*args,&block)
        end
      end
    LOLITA_SETUP
    configuration.send(method_name,*args,&block)
  end

  def self.load!
    load_frameworks!
    load_dependencies!
    load_base!

    self.send(:include, Lolita::Hooks)
    self.send(:add_hook, :before_setup, :after_setup, :after_routes_loaded,:before_routes_loaded)

  
    if rails?
      load_rails!
    end
    load_modules!
  end

  def self.load_frameworks!
    frameworks.each do |framework|
      begin
        require framework 
        puts "=> Loading Lolita #{version} with #{framework}"
      rescue Execption => e
        raise "Can't load #{framework}. Check you Gemfile."
      end
    end
  end

  def self.frameworks
    frameworks = []
    if rails?
      frameworks << "rails"
    end
    frameworks
  end

  def self.load_dependencies!
    require 'abstract'
    require 'observer'
    require 'ostruct'
    require "base64"
    require 'active_support'
    require 'active_support/core_ext/numeric/time'
    require 'active_support/core_ext/date_time/conversions'
    require 'active_support/concern'
    require 'active_support/callbacks'
    require 'active_support/dependencies'
    require 'active_support/inflector'
  end

  def self.load_base!
    Dir["#{File.dirname(__FILE__)}/lolita/ruby_ext/**/*.*"].each do |path|
      require path
    end
    require 'lolita/errors'
    require 'lolita/utils'
    require 'lolita/hooks'
    require 'lolita/mapping'
    require 'lolita/hooks/named_hook'
    require 'lolita/system_configuration/base'
    require 'lolita/system_configuration/application'
    require 'lolita/extensions/extensions'
  end

  def self.load_modules!
    require 'lolita/base'
    require 'lolita/orm'
    require 'lolita/configuration'
    require 'lolita/helpers'
    require 'lolita/processors/request_processor'
    require 'lolita/navigation/tree'
    require 'lolita/navigation/branch'

    require 'lolita/test/matchers'
    require 'lolita/support/formatter'
    require 'lolita/support/formatter/rails'

    require 'lolita/search/simple'
    require 'lolita/components/base'
    require 'lolita/components/configuration/column_component'
  end

  def self.load_rails!
    require 'kaminari'
    require 'jquery-rails'
    require 'tinymce-rails'
    require 'tinymce-rails-config-manager'
    require 'lolita/rails/railtie'
    require 'lolita/rails/engine'
  end

  def self.version
    Lolita::Version::STRING
  end

  def self.rails?
    defined?(::Rails)
  end

  def self.rails3?
    defined?(::Rails) && ::Rails::VERSION::MAJOR == 3
  end
end


Lolita.load!