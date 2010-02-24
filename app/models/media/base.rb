# Abstract class that is superclass of all #Media classes.
#Each subclass of Media::Base may have following class methods
# * after_parent_save(memory_id,parent,options) - method is called after parent
#   object is saved, method can get memory_id, parent object, and options
#   including (:params,:session,:cookies)
# * update_memorized_files(memory_id,parent) - can be used to update temporary
#   multimedia object with real parent id linked with memory_id.
#   See implementation in #Media::FileBase#update_memorized_files

# When new media type is created than that class must extend Media::Base so
# it can work right like Lolita Media class.
class Media::Base < Cms::Base
  self.abstract_class = true

  #Return all existing media names, for example 'audio' or 'image'
  # Return Array of all currently available media classes.
  # ====Example
  #     all_media_name #=> ['audio','video','image','simple']
  def self.all_media_names
    media=[]
    Find.find(File.dirname(__FILE__)) do |path|
      unless File.directory?(path)|| path.match(/_extensions/)
        base_name=File.basename(path,".rb")
        klass_name="Media::#{base_name.camelize}".constantize
        is_abstract=klass_name.respond_to?("abstract_class?") ? klass_name.abstract_class? : false
        if !is_abstract && klass_name.ancestors.include?(self)
          media<<base_name
        end
      end
    end
    media
  end

  # Determine whether given +object+ base class reflects to #Media class with <code>:has_many</code> association.
  # ====Example
  #     class Media::SimpleFile < Media::FileBase
  #       belongs_to :fileable, :polymorphic=>true
  #     end
  #     class User < Cms::Base
  #       has_many :data_files, :as=>:fileable
  #     end
  #     Media::SimpleFile.belongs_to_many?(User.find(:first)) #=> true
  def self.belongs_to_many?(object)
    reflection=object.class.base_class.reflect_on_association(self.get_current_media_class_reflection_by(object.class.base_class))
    reflection && reflection.macro==:has_many
  end

  # Determine whether given +object+ reflects to #Media class with <code>:has_one</code> association.
  # See #belongs_to_many? because this method return simply oposit of result of that method.
  def self.belongs_to_one?(object)
    !self.belongs_to_many?(object)
  end

  # Get given +klass+ reflection name for current #Media class.
  # ====Example
  #     class Media::SimpleFile < Media::FileBase
  #       belongs_to :fileable, :polymorphic=>true
  #     end
  #     class User < Cms::Base
  #       has_many :data_files, :as=>:fileable
  #     end
  #     Media::SimpleFile.get_current_media_class_reflection_by(User) #=> :data_files
  def self.get_current_media_class_reflection_by(klass)
    poly_name=self.media_get_polymorphic_name
    klass.reflections.collect{|reflection| reflection.last.options[:as]==poly_name ? reflection.first : nil}.compact.first
  end

  # Get current class polymorphic name. Goes through all reflections and return first reflection
  # with <code>:polymorphic</code> options.
  # ====Example
  #     class Media::SimpleFile < Media::FileBase
  #       belongs_to :fileable, :polymorphic=>true
  #     end
  #     Media::SimpleFile.media_get_polymorphic_name #=> :fileable
  def self.media_get_polymorphic_name
    self.reflections.collect{|reflection| reflection.last.options[:polymorphic] ? reflection.first : nil}.compact.first
  end
end