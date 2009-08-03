class AudioFile < FileBase
  has_one :picture, :as=>:pictureable, :dependent=>:destroy
  belongs_to :audio, :polymorphic=>true
  audio_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now
    "audio_file/name/#{time.strftime("%Y_%m")}/#{inst.id}"
  }
  named_scope :by_parent, lambda{|parent,parent_id|
    {:conditions=>["audio_type=? AND audio_id=?",parent.to_s.camelize,parent_id]}
  }
  def self.new_from_params(params)
    self.new_file(params)
  end

  def picture_url(version=nil)
    if self.picture && self.picture.picture
      if version
        self.picture.picture.send(version).url
      else
        self.picture.picture.url
      end
    else
      "/images/default.jpg"
    end
  end
end
