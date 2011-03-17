module Lolita
  module Configuration
  	class ContentTab < Lolita::Configuration::Tab

  	  def initialize(dbi,*args,&block)
        @type=:content
  	  	super
  	  	set_default_fields
  	  end

  	  private 

  	end
  end
end