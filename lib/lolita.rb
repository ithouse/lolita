$:<<File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))
LOLITA_VERSION=File.read(File.expand_path("../../VERSION",__FILE__)).gsub(/[^.\w]/,"")
FRAMEWORK = if defined?(Rails)
  " with Rails #{::Rails::VERSION::STRING}"
end
puts "=> Lolita #{LOLITA_VERSION} starting#{FRAMEWORK}"

#require "rubygems"
require 'abstract'
require 'observer'
require 'ostruct'
require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/concern'
require 'active_support/callbacks'
require 'active_support/dependencies'
require 'active_support/inflector'

# Require all ruby extensions
Dir["#{File.dirname(__FILE__)}/lolita/ruby_ext/**/*.*"].each do |path|
  require path
end

require 'lolita/errors'
# Hooks
require 'lolita/hooks'

module Lolita
  include Lolita::Hooks
  add_hook :before_setup, :after_setup, :after_routes_loaded,:before_routes_loaded

  @@scopes={}

  def self.scope name=nil
    name||=scope_name
    @@scopes[name]||=Lolita::SystemConfiguration::Base.new(name)
    @@scopes[name]
  end

  def self.setup
    self.run(:before_setup)
    yield scope
    self.run(:after_setup)
  end

  def self.scope_name
    :default
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
          scope.send(:#{method_name},*args,&block)
        end
      end
    LOLITA_SETUP
    scope.send(method_name,*args,&block)
  end

  def self.version
    @version ||= Lolita::Support::Version.new
  end

  def self.rails3?
    defined?(::Rails) && ::Rails::VERSION::MAJOR == 3
  end
  
end

require 'lolita/hooks/named_hook'

# Require base
require 'lolita/lazy_loader'
require 'lolita/observed_array'
require 'lolita/builder'
require 'lolita/controller_additions'

# System configuration
require 'lolita/system_configuration/base'
require 'lolita/system_configuration/application'

# Adapters
require 'lolita/adapter/field_helper'
require 'lolita/adapter/common_helper'
require 'lolita/adapter/abstract_adapter'
require 'lolita/adapter/active_record'
require 'lolita/adapter/mongoid'

# DBI
require 'lolita/dbi/base'

# Configuration base
require 'lolita/configuration/base'
require 'lolita/configuration/list'
require 'lolita/configuration/tabs'
require 'lolita/configuration/tab'
require 'lolita/configuration/columns'
require 'lolita/configuration/column'
require 'lolita/configuration/fields'
require 'lolita/configuration/field'
require 'lolita/configuration/field_set'
require 'lolita/configuration/nested_form'
require 'lolita/configuration/search'
require 'lolita/configuration/filter'

# Configuration factories
require 'lolita/configuration/factory/field'
require 'lolita/configuration/factory/tab'

# Configuration for fields and tabs
["field","tab"].each do |type|
  Dir["#{File.dirname(__FILE__)}/lolita/configuration/#{type}/**/*.*"].each do |path|
    base_name=File.basename(path,".rb")
    require "lolita/configuration/#{type}/#{base_name}"
  end
end

# Controllers and views
require 'lolita/controllers/internal_helpers'
require 'lolita/controllers/user_helpers'
require 'lolita/controllers/url_helpers'
require 'lolita/controllers/component_helpers'
require 'lolita/controllers/authorization_helpers'

# Test
require 'lolita/test/matchers'

# Navigation
require 'lolita/navigation/tree'
require 'lolita/navigation/branch'

# Support
require 'lolita/support/version'
require 'lolita/support/formatter'
require 'lolita/support/formatter/rails'

#Search
require 'lolita/search/simple'

if Lolita.rails3?
  require "base64"
  require 'kaminari'
  require 'tinymce-rails'
  require 'jquery-rails'
  require 'lolita/rails/all'
end
