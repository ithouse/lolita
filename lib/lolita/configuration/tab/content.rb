module Lolita
  module Configuration
    module Tab
    	class Content < Lolita::Configuration::Tab::Base

    	  def initialize(dbi,*args,&block)
          @type=:content
    	  	super
    	  	set_default_fields
    	  end

        def default_fields
          self.current_dbi.fields.map{|db_field|
            exclude_field?(db_field) ? nil : self.field(db_field)
          }.compact
        end

        def exclude_field?(db_field)
          db_field[:name].to_s.match(/^(created_at|updated_at|\w+_count)$/) ||
          (db_field[:name].match(/^\w+_id$/) && !association_column?(db_field[:name]))
        end

        def association_column?(name)
          self.respond_to?(name.gsub(/_id$/,"").to_sym)
        end

    	  private 


        def set_default_fields
          default_fields if @fields.empty? 
        end
        
    	end
    end
  end
end