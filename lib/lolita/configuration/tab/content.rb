module Lolita
  module Configuration
    module Tab
    	class Content < Lolita::Configuration::Tab::Base

    	  def initialize(*args,&block)
    	  	super
    	  	set_default_fields
    	  end

    	  private 

        def set_default_fields
          default_fields if @fields.empty? 
        end
        
    	end
    end
  end
end