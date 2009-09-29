module Extensions
  module Cms
    module HandleRelations
      protected

      # set_instance_variable_for_nested_attributes can be overwritten in managed_before_open callbacks
      # manage_nested_params can be overwritten in managed_before_save callbacks
      # Related model must specifie accepts_nested_attributes_for otherwise error will be rised

      # Create instance variable so related tab fields can be filled with information
      # Check all tabs to see if there any tab with :object attribute, than check
      # if current @object has getter with :object value name and than create
      # instance variable with that name
      #
      # Useful when tab :object is reflection name.
      # @object => Admin::User
      # @object.profile => Admin::Profile
      def set_instance_variable_for_nested_attributes
        @config[:tabs].each{|tab|
          if tab[:object] && @object.respond_to?(tab[:object])
            self.instance_variable_set(:"@#{tab[:object]}",@object.send(tab[:object])) unless self.instance_variable_get(:"@#{tab[:object]}")
          end
        }
      end
      # Goes through all tabs and check if there any tab that has :object and if that
      # :object value is reflection of current ActiveRecord class object, if so
      # than move all related data from params to params[:object] Hash to save it like
      # related attributes.
      # Example.
      # @my_params => {:object=>{:login=>"Login"},:profile=>{:name=>"Name"}
      # After manage_nested_params
      # @my_params => {:object=>{:login=>"Login",:profile_attributes=>{:name=>"Name"}}}
      def manage_nested_params
        @config[:tabs].each{|tab|
          if tab[:object] && object.reflect_on_association(tab[:object])
            temp_container=@my_params[tab[:object]].dup
            @my_params.delete(tab[:object])
            attributes_name="#{tab[:object]}_attributes".to_sym
            @my_params[:object][attributes_name]=temp_container unless @my_params[:object][attributes_name]
          end
        }
      end
      #Funkcija apstrādā 1 pret n saiti, kas tiek saņemta ja ir izmantoti 'checkbox'
      #elements ievades formā, kur tekošajam elementam var tikt piesaistīti vairāki cita
      #moduļa elementi
      def handle_has_many_relation
        @config[:tabs].each{|tab|
          tab_fields(tab).each{|field|
            if field[:type].to_sym==:checkboxgroup && my_params[tab[:object]||:object] && my_params[tab[:object]||:object][field[:field]]
              remote_object=object.reflect_on_association(field[:field]).klass
              my_params[tab[:object]||:object][field[:field]].collect!{|id| remote_object.find_by_id(id)}.compact!
            end
          }
        }
      end
    end #module end
  end
end