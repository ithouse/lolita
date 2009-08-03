module Extensions::FileHelper
  def file_source file
    if file and !file.name.nil?
      return file.name.url
    end
  end
  
  def get_all_parent_files(options={})
    session_parent_id = ("t"+options[:parnet_id].to_s).to_sym
    media="uploaded_#{options[:media].to_s.pluralize}".to_sym
    class_name=options[:media].to_sym==:file ? FileItem : options[:media].to_s.camelize.constantize
    if session[media] && session[media][session_parent_id]
      files=class_name.find(session[media][session_parent_id])
    else
      polymorphic_name=class_name.reflections.collect{|reflection| reflection.last.options[:polymorphic] ? reflection.first : nil}.compact.first
      files=class_name.find(:all,:conditions=>["#{polymorphic_name}_type=? AND #{polymorphic_name}_id=?",options[:parent].camelize,options[:parent_id]])
    end
    yield files
  end
end
