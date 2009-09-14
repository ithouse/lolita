class Media::GoogleMap < Media::Base
  set_table_name :media_google_maps
  belongs_to :mappable, :polymorphic=>true

  def self.after_parent_save(memory_id,object,options)
    self.find_by_parent(object).each{|m| m.destroy}
    object_class=object.class.base_class.to_s
    points=[]
    options[:params][:map].each{|map_id,maps|
      maps.each{|marker_id,marker|
        points<<self.create!(:lat=>marker[:lat],:lng=>marker[:lng],:mappable_type=>object_class,:mappable_id=>object.id)
      }
    } if options[:params][:map].is_a?(Hash)
    object.class.assing_polymorphic_result_to_object(object,points,:mappable)
  end

  def self.find_by_parent(object)
    self.find(:all,:conditions=>["mappable_id=? AND mappable_type=?",object.id,object.class.base_class.to_s])
  end
  
  def self.collect_coords(object)
    result={:lat=>[],:lng=>[],:description=>[]}
    if object
      self.find_by_parent(object).each{|m|
        result[:lat]<<m.lat
        result[:lng]<<m.lng
        result[:description]<<m.description
      }
    end
    result
  end
  
  def self.collect_lat(object)
    self.collect_coords(object)[:lat]
  end

  def self.collect_lng(object)
    self.collect_coords(object)[:lng]
  end
end
