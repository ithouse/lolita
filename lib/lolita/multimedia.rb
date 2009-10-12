module Lolita
  module Multimedia
    def self.included(base)
      base.class_eval{
        include InstanceMethods
      }
    end

    module InstanceMethods
      def update_multimedia(object,id)
        Media::Base.all_media_names.each{|media|
          klass="Media::#{"#{media}".camelize}".constantize
          klass.after_parent_save(id,object,{:params=>params,:session=>session,:cookies=>cookies}) if klass.respond_to?(:after_parent_save)
          klass.update_memorized_files(id,object) if klass.respond_to?(:update_memorized_files)
        }
      end

      private

      def has_file_id?
        params[:temp_file_id].to_i>0
      end
      def file_id
        params[:temp_file_id] || nil
      end
    end
  end
end