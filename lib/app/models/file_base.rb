class FileBase < Cms::Base
  self.abstract_class = true

  def self.new_file(params)
    file=self.new()
    if params[:tempid]!="true" && params[:parent_id]
      parent=params[:parent].camelize.constantize.find_by_id(params[:parent_id])
      polymorphic_name=self.reflections.collect{|reflection| reflection.last.options[:polymorphic] ? reflection.first : nil}.compact.first
      file.send("#{polymorphic_name}=",parent) if parent
    end
    file.name=params[params[:media].to_sym][:name] if params[params[:media].to_sym]
    file
  end

  def self.clear_temp_files
    ref=self.reflections.detect{|name,r| r.options[:polymorphic]}
    if ref
      self.delete_all(["#{ref.first}_type IS NULL AND #{ref.first}_id IS NULL AND created_at<=?",1.day.ago])
    end
  end

  def self.update_temp_files(parent,ses_arr,poly_name)
    ses_arr.collect{|id|
      if file = self.find_by_id(id)
        file.update_attributes!(:"#{poly_name}_type"=>parent.class.to_s,:"#{poly_name}_id"=>parent.id)
        file
      end
    }.compact
  end

end