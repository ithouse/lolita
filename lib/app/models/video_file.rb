class VideoFile < FileBase
  belongs_to :video, :polymorphic=>true
  has_one :picture, :as=>:pictureable, :dependent=>:destroy
  video_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now
    "video_file/name/#{time.strftime("%Y_%m")}/#{inst.id}"
  }
  
  after_save :create_picture_if_needed
  after_save :set_ratio
  named_scope :by_parent, lambda{|parent,parent_id|
    {:conditions=>["video_type=? AND video_id=?",parent.to_s.camelize,parent_id]}
  }

  def add_head
    FFMPEG.join(:input=>[RAILS_ROOT+"/public/swf/head_wide.flv",self.name.url],:output=>self.name.url)
  end
  
  def self.new_from_params(params)
    file=self.new_file(params)
    file.with_intro=params[:intro] ? true : false
    file
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

  private

  def create_picture_if_needed
    if !self.picture && self.name
      require 'ffmpeg'
      require 'action_controller/test_process'
      destination=Picture.get_temp_destination()
      file_name="second_1_#{self.name.to_s.gsub(/\.\w+$/,"")}.png"
      begin
        Picture.transaction do
          Dir.mkdir(destination) unless File.exist?(destination)
          set_first_frame_image(destination,file_name)
          up_image=File.new("#{destination}/#{file_name}","rb")
          picture=Picture.create_with_parent!(self,:picture=>up_image,:watermark_free=>true)
          self.picture=picture
          up_image.close()
        end
      rescue => exception
        a=1
      ensure
        remove_temp_image(destination)
      end
    end
    true
  end

  def set_ratio
    destination=Picture.get_temp_destination
    begin
      if !self.picture && self.name
        Dir.mkdir(destination) unless File.exist?(destination)
        set_first_frame_image(destination,"temp_picture.png")
        img=::Magick::Image::read("#{destination}/temp_picture.png").first
      elsif self.picture
        img=::Magick::Image::read("#{RAILS_ROOT}/public/#{self.picture.picture.url}").first
      end
      if img
        w=img.columns
        h=img.rows
        connection.update("UPDATE #{self.class.table_name} SET ratio=#{h.to_f/w.to_f} WHERE id=#{self.id}")
      end
    rescue => exception

    ensure
      remove_temp_image(destination)
    end
  end
  
  def set_first_frame_image(destination,filename,type="png")
    FFMPEG.video_screenshot(:input=>"#{RAILS_ROOT}/public#{self.name.url}",:format=>type,:output=>"#{destination}/#{filename}")
    # File.chmod("660","#{destination}/#{filename}")
  end

  def remove_temp_image(destination)
    FileUtils.rm_rf destination
    GC.start
  end
end
