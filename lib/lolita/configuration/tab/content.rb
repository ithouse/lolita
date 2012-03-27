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

        def validate(tab, options={})
          if (options[:tabs] || []).detect{|existing_tab| existing_tab.type == :content}
            raise Lolita::SameTabTypeError, "Same type tabs was detected (#{tab.type})."
          end
        end
        
    	end
    end
  end
end