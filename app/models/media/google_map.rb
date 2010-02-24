# Default #Lolita media module for GoogleMaps, that allow to add one or more
# points at map. Include acts_as_mappable plugin, that allow to operate with
# coordinates and simply find points in specific areas.
class Media::GoogleMap < Media::Base
  set_table_name :media_google_maps
  belongs_to :mappable, :polymorphic=>true
  acts_as_mappable if Lolita.config.system :geokit

  # After parent is saved that calls this method and create
  # map points and link them with parent object, this is default Lolita media interface.
  def self.after_parent_save(memory_id,object,options)
    #FIXME vajag izdomāt, kā notiekt, ka tiek ne no CMS puses pievienots punkts kkādā
      # citā stilā, un tad tur izmainīt
    if options[:params][:map].is_a?(Hash)
      self.find_by_parent(object).each{|m| m.destroy}
      object_class=object.class.base_class.to_s
      points=[]
      options[:params][:map].each{|map_id,maps|
        maps.each{|marker_id,marker|
          if marker[:lng].to_s!="0" && marker[:lat]!="0"
            points<<self.create!(
              :lat=>marker[:lat],
              :lng=>marker[:lng],
              :zoom=>marker[:zoom],
              :mappable_type=>object_class,
              :mappable_id=>object.id
            )
          end
        }
      }
      object.class.assing_polymorphic_result_to_object(object,points,:mappable)
    end
    
  end

  # Find points by parent _object_.
  def self.find_by_parent(object)
    self.find(:all,:conditions=>["mappable_id=? AND mappable_type=?",object.id,object.class.base_class.to_s])
  end

  # Return Hash of information about parent _object_ points.
  # ====Example
  #     Media::GoogleMap.collect_coords(object)
  #     #=> {:lat=>[23.332323],:lng=>[40.232332],:description=>["nice place"]}
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

  # Return only latitudes for parent _object_ points as Array.
  def self.collect_lat(object)
    self.collect_coords(object)[:lat]
  end

  # Return only longitutes for parent _object_ poins as Array.
  def self.collect_lng(object)
    self.collect_coords(object)[:lng]
  end
end
