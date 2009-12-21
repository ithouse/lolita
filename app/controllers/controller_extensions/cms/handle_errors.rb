module ControllerExtensions
  module Cms
    # Do stuff with error for #Managed
    module HandleErrors

      # Merge two object errors _object_ and <em>other_object</em> by adding
      # all _errors_ to _object_.
      def merge_errors object,ext_obj
        if ext_obj.respond_to?(:errors) && !ext_obj.errors.empty? && object.respond_to?(:errors)
          ext_obj.errors.each{|attr,msg|
            object.errors.add(attr,msg[0])
          }
        end
      end
      #beidzas funkcijas
    end
  end
end
