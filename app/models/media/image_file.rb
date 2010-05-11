# coding: utf-8
# Default #Lolita image class, that provide functionality for storing, rebuilding,
# compressing and doing other stuff with images.
class Media::ImageFile < Media::FileBase
  require 'RMagick'
  set_table_name :media_image_files
  attr_accessor :watermark_free
  belongs_to :pictureable, :polymorphic => true
  # Default image versions for Lolita.
  VERSIONS={
    :cropped=>"420x420",
    :thumb =>"124x124"
  }.freeze
  # Images is stored in /public/upload/image/files/name/[year_month]/[picture.id]
  image_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now 
    "image_file/name/#{time.strftime("%Y_%m")}/#{inst.id}"

  },:versions => VERSIONS.dup,
    :process => Lolita.config.system(:default_image_size)

  before_save :assign_position
  before_save :singularize_main
  # after_save :add_watermarks, :if=>"watermark_free.nil? && !watermark_added"
  # before_destroy :delete_pdf
  named_scope :by_pictureable, lambda{|parent|
    {:conditions=>{:pictureable_type=>parent.class.to_s,:pictureable_id=>parent.id}}
  }
  named_scope :by_parent, lambda { |type,id|
    { :conditions => { :pictureable_type=>type.to_s.camelize, :pictureable_id=>id } }
  }
  named_scope :positioned, lambda{|direction|
    {:order=>"position #{direction || "asc"}"}
  }
  named_scope :after, lambda{|position|
    {:conditions=>["position>?",position]}
  }
  named_scope :before, lambda{|position|
    {:conditions=>["position<?",position]}
  }
  named_scope :main,:conditions=>{:main_image=>true}
  named_scope :by_ids, lambda{|ids|
    {:conditions=>["id IN (?)",ids]}
  }

  # Return all versions available for image as Hash of version name and dimensions.
  # ====Example
  #     Media::ImageFile.find(:first).full_versions #=> {:cropped=>"420x420",:thumb=>"124x124"}
  def full_versions
    version_class=self.pictureable_type.constantize
    class_versions=version_class.respond_to?(:upload_column_versions) ? version_class.upload_column_versions : {}
    Media::ImageFile::VERSIONS.merge(class_versions || {})
  end

  # Return all versions that crop image.
  # ====Example
  #     Media::ImageFile.find(:first).cropped_versions #=> {:my_size=>"c100x200"}
  def cropped_versions
    result={}
    self.full_versions.each{|name,dimensions|
      if dimensions=~/^c/
        result[name]=dimensions
      end
    }
    result
  end

  # Detect whether or not image has versions that crop it. See #cropped_versions
  def has_cropped_versions?
    self.cropped_versions.keys.size>0
  end

  # Take all images, that are newer that 30 days and that are not compressed yet.
  # Resize real image that was uploaded to 1000px width and 700px height.
  # In console you may see progress of compressing.
  # After compressing update all records that match conditions, update those pictures, that
  # may not be compressed as well.
  # When error raises show picture ID that cannot be recreated.
  def self.compress_old
    #require 'RMagick'
    conditions=["created_at<? AND is_compressed=?",30.days.ago,false]
    pictures=self.find(:all,:conditions=>conditions)
    time=Time.now
    puts "Start compressing #{pictures.size} files at #{time.strftime("%Y.%m.%d %H:%M:%S")}!"
    step=pictures.size/20
    errors=[]
    pictures.each_with_index{|p,i|
      putc "." if i%step==0
      begin
        path=p.name.path
        img=::Magick::Image::read(path).first
        img.resize_to_fit!(1000,700)
        img.write(path)
        GC.start
      rescue
        errors<<"Unable to compress #{path}"
      end
    } if step > 0
    puts ""
    begin
      self.update_all("is_compressed=1",conditions)
      puts "Database updated!"
    rescue
      puts "Database update FAILED!"
    end
    errors.each{|e|
      puts e
    }
    etime=Time.now
    puts "Compressing done in #{etime.hour-time.hour}:#{etime.min-time.min}:#{etime.sec-time.sec}!"
  end

  # Method goin through all pictures
  # Delete all version files
  # Create new file with current dimensions
  # you can pass options
  # - :conditions => will rebuild these pictures only
  # When new version(-s) is(-are) added  or removed and you need that images that were uploaded
  # before have those versions too, than you need to call this method to
  # rebuild all pictures that you need.
  # Accepted _options_:
  # * <tt>:conditions</tt> - Find conditions for Media::Image file to find exect images
  #                          that need to be rebuilded.
  # Method goes through all pictures and check if there exists directory for
  # that picture, if not then delete record from DB.
  # After that if image exists, than then delete all version and keep only original.
  # Than take all available versions for image and create new version files from
  # that dimensions that provide version Hash. See #full_versions.
  # Finally shows all pictures IDs that were unable to rebuild and last error that
  # was raised.
  def self.rebuild(options = {})
    errors=[]
    temp_path="#{RAILS_ROOT}/tmp/picture_rebuild"
    Dir.mkdir(temp_path) unless File.exist?(temp_path)

    start_time=Time.now
    all_pictures=Media::ImageFile.find(:all,:conditions => options[:conditions])
    count=all_pictures.size
    decs=1
    border_count=count/10
    puts "Total pictures: #{count}"
    all_pictures.each_with_index{|p,index|
      if index>border_count
        puts "#{index} done #{count-index} to go! (#{Time.now.strftime("%Y-%m-%d %H:%M:%S")})"
        decs+=1
        border_count=count/10*decs
      end
      begin
        path=p.name.path
        unless File.exists?(p.name.dir)
          Media::ImageFile.delete p.id
        else
          Find.find(p.name.dir){|full_path|
            unless File.directory?(full_path) || full_path==path
              File.delete(full_path)
            end
          }
          default_img=::Magick::Image::read(path).first
          p.full_versions.each{|n,v|
            main_img=default_img.clone
            if v.match(/c/)
              g=v.gsub("c","")
              g=g.split("x")
              main_img.crop_resized!(g[0].to_i,g[1].to_i)
            else
              g=v.split("x")
              main_img.resize_to_fit!(g[0].to_i,g[1].to_i)
            end
            parts=p.name.filename.split(".")
            extension=parts[1].to_s.size>0 ? parts.pop : nil
            basename=parts.join(".")
            main_img.write("#{p.name.dir}/#{basename}-#{n}#{extension ? "." : ""}#{extension}")
            GC.start
          }
          p.name_after_upload(p.name)
        end
      rescue Exception=>e
        errors<<"Unable rebuild #{p.id}"
        @last_error = e
      end
    }
    puts "Average speed: #{all_pictures.size.to_f/(Time.now-start_time).to_f} (pictures/second)"
    puts @last_error
    errors
  end

  # Method is used to recreate some of the #cropped_versions of image for different
  # look. When image is created the cropped versions may not look as expected, then
  # this method can be called to take different part from original picture to create
  # new cropped version for that image.
  # Accpeted _options_:
  # * <tt>:id</tt> - ID of Media::ImageFile
  # * <tt>:version</tt> - Version name that need to be recreated.
  # * <tt>:x</tt> - New x position in original where new image left top corner is positioned
  # * <tt>:y</tt> - New y position in original where new image left top corner is positioned
  # * <tt>:width<tt/> - New image width in px in original image.
  # * <tt>:height</tt> -  New image height in px in originl image.
  # Method take original image and calculate new dimensions (see #chopped_image) and
  # manipulate with original then do croping or resazing and then write in over old file.
  # ====Example
  #     Media::ImageFile.recreate({
  #       :id=>1,
  #       :version=>:my_size,
  #       :x=>1,
  #       :y=>16,
  #       :width=>500, # width in original image
  #       :height=>600 # height in original image
  #     }) #=> return info or empty string
  def self.recreate(options={})

    p=self.find_by_id(options[:id])
    p_versions=p.cropped_versions if p
    if p && p_versions.keys.include?(options[:version].to_sym)
      path=p.name.send(options[:version]).path #read path so i now where to write
      img=::Magick::Image::read(p.name.path).first #read original image
      chopped=chopped_image(p,img,options) #cut from original needed part
      dimensions=p_versions[options[:version].to_sym] #get dimension
      if dimensions.include?("c") #check if need to crop or not
        dimensions=dimensions.gsub("c","").split("x")
        chopped.crop_resized!(dimensions[0].to_i,dimensions[1].to_i) #do cropping
      else
        dimensions=dimensions.split("x")
        chopped.resize_to_fit!(dimensions[0].to_i,dimensions[1].to_i) #do resizing
      end
      chopped.write(path) #write new image over old one
      if watermark54=self.get_watermark
        p.add_watermark(watermark54,options[:version])
      end
      GC.start
    end
    p ? p.version_info(options[:version]) : ""
  end

  # Used for #Lolita.
  # When block given yield cropped versions and Hash of:
  # * <tt>:width</tt> - real width in px
  # * <tt>:height</tt> - real height in px
  # * <tt>:cropped</tt> - whether or not image is cropped, always true
  # * <tt>:t</tt> - Translated image name, thke names from <i>image file.version.[version name]</i>
  # When not block given then return Hash or all versions as key and values is Hash of information
  # about image same as when block is given.
  def versions
    if block_given?
      self.cropped_versions.each{|key,value|
        yield key,dimensions_in_parts(value).merge({:t=>I18n.t(:"image file.versions.#{key}")})
      }
    else
      result={}
      self.cropped_versions.each{|key,value|
        result[key]=dimensions_in_parts(value).merge({:t=>I18n.t(:"image file.versions.#{key}")})
      }
      result
    end
  end


  # Specific function for image cropping dialog.
  # Return Hash where key is cropped version name and values is Hashes see #version_info for detail.
  def versions_info
    info={}
    self.cropped_versions.each{|name,diminsions|
      info[name]=self.version_info(name)
    }
    info
  end

  # Return image version info for given version _name_.
  # ====Example
  #     Media::ImageFile.find(:first).version_info(:my_size)
  #     #=> {
  #       :width=>100,
  #       :height=>200,
  #       :h_diff=>1, # because 200>100
  #       :w_diff=>100/200,
  #       :url=>/public/upload/image_file/name/2010_02/1/image_name_my_size.jpg
  #     }
  def version_info(name)
    w,h=self.width(name),self.height(name)
    if w && h
      {
        :width=>w,
        :height=>h,
        :h_diff=>w>h ? h.to_f/w.to_f : 1,
        :w_diff=>h>w ? w.to_f/h.to_f : 1, #width*w_diff
        :url=>self.url(name)
      }
    end
  end

  # Return width in px for given _version_.
  def width(version)
    if self.name and version
      begin
        Magick::Image.read(self.name.send(version).path).first.columns
      rescue
        0
      end
    else
      0
    end
  end

  # Return height for given _version_.
  def height(version)
    if self.name and version
      begin
        Magick::Image.read(self.name.send(version).path).first.rows
      rescue
        0
      end
    else
      0
    end
  end

  # Return file type for uploaded file.
  # When file tipe is <i>jpg</i> then return <i>jpeg</i>.
  def type
    ext=self.name.path.match(/\.(\w+)$/)
    if ext
      ext=$1.dup
      case ext
      when "jpg"
        "jpeg"
      else
        ext
      end
    else
      ""
    end
  end

  # Return url for given _version_. This is a shorter way and exception safe.
  # ====Example
  #     Media::ImageFile.first.url(:main) #=> /public/upload/image_file/name/2010_02/1/file_main.jpeg
  def url(version=nil)
    if self.name
      if version
        self.name.send(version).url
      else
        self.name.url
      end
    else
      ""
    end
  end

  # Specific method for collecting information that yield
  # version translation and dimensions and values is Hash that contains
  # url, width and height of image.
  def all_versions
    result={}
    self.full_versions.each{|v,d|
      result["#{I18n.t(:"image file.versions.#{v}")} (#{d})"]={:url=>self.url(v),:width=>self.width(v),:height=>self.height(v)}
    }
    result.each{|key,value|
      yield key,value,self
    }
  end

  # Create new Media::Image file with given _parent_ and _attributes_.
  def self.create_with_parent! parent,attributes={}
    if parent
      picture=Media::ImageFile.new(attributes.merge(:pictureable_type=>parent.class.to_s,:pictureable_id=>parent.id))
      picture.save!
      picture
    else
      raise "Nav norādīts vecāka objekts!"
    end
  end

  # Create new image from received _params_.
  # Set main image as <i>true</i> or <i>nil</i>, if passed :single in _params_.
  def self.new_from_params params={}
    file=self.new_file(params)
    file.main_image=params[:single]=="true" ? true : nil
    file
  end

  # Return next image that follows _this_ image.
  def next_picture
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("asc").after(self.position).first
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("asc").first unless picture
    picture
  end

  # Return previous image that is before _this_ image.
  def prev_picture
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("desc").before(self.position).first
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("asc").last unless picture
    picture
  end

  # Deprecated!
  # Add watermark to picture from passed _watermark_ image object (RMagick object)
  # for given _version_.
  def add_watermark(watermark,version=nil)
    # chopped.resize_to_fit!(dimensions[0].to_i,dimensions[1].to_i)
    url="#{RAILS_ROOT}/public/#{version ? self.name.send(version).url : self.name.url}"
    image = Magick::Image.read(url).first
    height=image.rows
    width=image.columns
    w_height=watermark.rows
    w_width=watermark.columns
    if (w_width.to_f/width.to_f)>0.17 || w_height.to_f/height.to_f>0.17
      watermark=watermark.resize_to_fit(0.17*height,0.17*width)
      padding_x=width*0.02
      padding_y=height*0.02
    else
      padding_x=5
      padding_y=5
    end
    image=image.composite(watermark,Magick::NorthEastGravity,padding_x,padding_y,Magick::OverCompositeOp)
    image.write(url)
  end

  #if in public image directory has image_file_watermark.png then add it to uploaded
  #image and if before_save callback is enabled
  # Get watermark file, if exists. Watermark file need to exist in following path
  # /public/images/image_file_watermark.png
  def self.get_watermark
    if File.exist?(RAILS_ROOT+"/public/images/image_file_watermark.png")
      Magick::Image.read(RAILS_ROOT+"/public/images/image_file_watermark.png").first
    end
  end

  # Add watermarks for all version, see #add_watermark for details.
  def add_watermarks
    if self.name && watermark54=Media::ImageFile.get_watermark
      self.full_versions.each{|version,dimensions|
        add_watermark(watermark54,version,dimensions)
      }
      self.toggle!(:has_watermark)
    end
  end

  # Return temp destination to operate with image files, that do not need to store.
  def self.get_temp_destination
    timestamp="#{rand(100000)}"+Time.now.strftime("%Y%m%d%H%M%S")
    "#{RAILS_ROOT}/public/upload/#{self.to_s.underscore}/name/tmp/#{timestamp}"
  end

  # Used in upload column, that is patched for #Lolita.
  # Collect all versions for uploaded file, versions is collected for
  # parent class.
  def before_upload options={}
    versions_class=self.pictureable_type.constantize
    if versions_class.respond_to?(:upload_column_versions)
      c_versions=versions_class.upload_column_versions
      options[:versions].merge!(c_versions) if c_versions
    end
    options
  end

  # Default UploadColumn callback, that is called after upload is done.
  # Call modify method for uploded file. See #Lolita::HasAttachedFile
  def name_after_upload(picture)
 
    versions_class=self.pictureable_type.constantize
    if versions_class.respond_to?(:upload_column_modify_methods) && methods=versions_class.upload_column_modify_methods
      methods.each{|m,values|
        versions_class.send(m,picture,values)
      }
    end
  end
  protected

  # If main image is set to <i>true</i> then other images that belongs to same parent
  # _main_image_ attribute is set to <i>false</i>.
  def singularize_main
    if @changed_attributes && @changed_attributes.has_key?('main_image') && self.main_image
      old_main=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).main.find(:first)
      old_main.update_attributes!(:main_image=>nil) if old_main
    end
  end

  # Get new image from given _img_ and chop part of it depending on passed picture (_p_) and
  # passed options. See Media::ImageFile#recreated
  def self.chopped_image(p,img,options={})
    crop_img=::Magick::Image::read(p.name.cropped.path).first #ielasu croppable bildi
    c_width=crop_img.rows
    c_height=crop_img.columns
    b_width=img.rows
    b_height=img.columns
    w_diff=b_width.to_f/c_width.to_f
    h_diff=b_height.to_f/c_height.to_f
    img.crop(options[:x].to_i*w_diff,options[:y].to_i*h_diff,options[:width].to_i*w_diff,options[:height].to_i*h_diff)
  end

  # Split dimension String (_size_) in parts and return Hash of
  # dimensions.
  # ====Example
  #     dimensions_in_part("c100x200") #=> {:width=>100,:height=>200,:crop=>true}
  def dimensions_in_parts(size)
    d=size.to_s.split("x")
    if d.size>0
      if d[0].include?("c")
        w=d[0].gsub("c","")
        c=true
      else
        w=d[0]
        c=false
      end
      {:width=>w,:height=>d[1],:crop=>c}
    else
      {}
    end
  end

  # Assign position for image, if image doesn't have positio yet, then
  # calculate it by adding +1 to maximum position of parent pictures positions.
  def assign_position
    if (self.pictureable_id.to_i>0 && !self.position)
      current_position=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).maximum("position")
      current_position=current_position ? current_position+1 : 1
      self.position=current_position
    end
  end
 
end
