class Media::Base < Cms::Base
  self.abstract_class = true

  #Each subclass of Media::Base may have following class methods
  # * after_parent_save(memory_id,parent,options) - method is called after parent
  #   object is saved, method can get memory_id, parent object, and options
  #   including (:params,:session,:cookies)
  # * update_memorized_files(memory_id,parent) - can be used to update temporary
  #   multimedia object with real parent id linked with memory_id.
  #   See implementation in #Media::FileBase.#update_memorized_files


  
  #Return all existing media names, for example 'audio' or 'image'
  def self.all_media_names
    media=[]
    Find.find(File.dirname(__FILE__)) do |path|
      unless File.directory?(path)
        base_name=File.basename(path,".rb")
        klass_name="Media::#{base_name.camelize}".constantize
        is_abstract=klass_name.respond_to?("abstract_class?") ? klass_name.abstract_class? : false
        unless is_abstract
          media<<base_name
        end
      end
    end
    media
  end

   #Return media class polymorphic name
  def self.media_get_polymorphic_name
    self.reflections.collect{|reflection| reflection.last.options[:polymorphic] ? reflection.first : nil}.compact.first
  end
end