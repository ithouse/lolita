
LOLITA_ROOT=File.dirname(__FILE__)
$:<<LOLITA_ROOT unless $:.include?(LOLITA_ROOT)

require 'lolita/rails_additions'

module Lolita
  autoload(:LazyLoader,'lolita/lazy_loader')
  autoload(:VERSION,'lolita/version')
  autoload(:ObservedArray,'lolita/observed_array')
  module Adapter
    Dir.new(File.join(LOLITA_ROOT,'lolita','adapter')).each{|file|
      base_name=File.basename(file,".rb")
      autoload(:"#{base_name.camelize}","lolita/adapter/#{base_name}") if file.match(/\.rb$/)
    }
  end

  module DBI
    Dir.new(File.join(LOLITA_ROOT,'lolita','dbi')).each{|file|
      base_name=File.basename(file,".rb")
      autoload(:"#{base_name.camelize}","lolita/dbi/#{base_name}") if file.match(/\.rb$/)
    }
  end
  
  module Configuration
    Dir.new(File.join(LOLITA_ROOT,'lolita','configuration')).each{|file|
      base_name=File.basename(file,".rb")
      autoload(:"#{base_name.camelize}","lolita/configuration/#{base_name}") if file.match(/\.rb$/)
    }

    def self.included(base)
      base.class_eval do
        extend ClassMethods
        def lolita # tikai getteris
          self.class.lolita
        end
      end
    end

    module ClassMethods
      def lolita(&block)
        Lolita::LazyLoader.lazy_load(self,:@lolita,Lolita::Configuration::Base,self,&block)
      end
      def lolita=(value)
        if value.is_a?(Lolita::Configuration::Base)
          @lolita=value
        else
          raise ArgumentError.new("Only Lolita::Configuration::Base is acceptable.")
        end
      end
    end

  end
end