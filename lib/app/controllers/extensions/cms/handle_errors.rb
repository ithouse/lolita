module Extensions
  module Cms
    module HandleErrors

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
