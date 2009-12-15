module Lolita
  module Multimedia
    def self.included(base) # :nodoc: 
      base.class_eval{
        include InstanceMethods
      }
    end

    # To get temporary multimedia id *file_id* should be used.
    # To check if temporary multimedia id is set <b>has_file_id?</b> should be used.
    module InstanceMethods
      # Update all multimedia classes with real _object_ id when _object_ is created.
      # ====Example
      #     update_multimedia(Cms::Blog.create!(params[:blog]), file_id())
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