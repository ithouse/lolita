class Media::ImageFile < Media::FileBase
  require 'RMagick'
  set_table_name :media_image_files
  attr_accessor :watermark_free
  belongs_to :pictureable, :polymorphic => true

  VERSIONS={
    :cropped=>"420x420",
    :thumb =>"124x124"
  }
  image_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now #vienīgā šaize var būt, ja mēneše pēdējā dienā 23:59:59 uploado
    "image_file/name/#{time.strftime("%Y_%m")}/#{inst.id}"
  },:versions => VERSIONS

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

  ##############################################################################
  def full_versions
    version_class=self.pictureable_type.constantize
    class_versions=version_class.respond_to?(:upload_column_versions) ? version_class.upload_column_versions : {}
    Media::ImageFile::VERSIONS.merge(class_versions || {})
  end

  def cropped_versions
    result={}
    self.full_versions.each{|name,dimensions|
      if dimensions=~/^c/
        result[name]=dimensions
      end
    }
    result
  end

  def has_cropped_versions?
    self.cropped_versions.keys.size>0
  end
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
  # Add watermak if exists
  def self.rebuild(all=false)
    errors=[]
    temp_path="#{RAILS_ROOT}/tmp/picture_rebuild"
    Dir.mkdir(temp_path) unless File.exist?(temp_path)
    watermark=self.get_watermark

    start_time=Time.now
    all_pictures=Media::ImageFile.find(:all)#,:conditions=>["created_at>?",1.month.ago]
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
          extension=parts.pop
          basename=parts.join(".")
          main_img.write("#{p.name.dir}/#{basename}-#{n}.#{extension}")
          p.add_watermark(watermark,n) if watermark
          GC.start
        }
      rescue
        errors<<"Unable rebuild #{p.id}"
      end
    }
    puts "Average speed: #{all_pictures.size.to_f/(Time.now-start_time).to_f} (pictures/second)"
    errors
  end

  def self.recreate(options={})

    p=self.find_by_id(options[:id])
    p_versions=p.cropped_versions if p
    if p && p_versions.keys.include?(options[:version].to_sym)
      path=p.name.send(options[:version]).path #ielasu ceļu lai zinātu kur rakstīt
      img=::Magick::Image::read(p.name.path).first #ielasu bāzes attēlu
      chopped=chopped_image(p,img,options) #no tā izgriežu vajadzīgo daļu
      dimensions=p_versions[options[:version].to_sym] #iegūstu dimensijas
      if dimensions.include?("c") #nosaku vai kropot vai nē
        dimensions=dimensions.gsub("c","").split("x")
        chopped.crop_resized!(dimensions[0].to_i,dimensions[1].to_i) #kropoju
      else
        dimensions=dimensions.split("x")
        chopped.resize_to_fit!(dimensions[0].to_i,dimensions[1].to_i) #resaizoju
      end
      chopped.write(path) #uzrakstu jauno bildi pa virsu
      if watermark54=self.get_watermark
        p.add_watermark(watermark54,options[:version])
      end
      GC.start #novācu visu lieko
    end
    p ? p.version_info(options[:version]) : ""
  end

  def versions
    if block_given?
      self.cropped_versions.each{|key,value|
        yield key,dimensions_in_parts(value).merge({:t=>t(:"image file.versions.#{key}")})
      }
    else
      result={}
      self.cropped_versions.each{|key,value|
        result[key]=dimensions_in_parts(value).merge({:t=>t(:"image file.versions.#{key}")})
      }
      result
    end
  end

  def versions_info
    info={}
    self.cropped_versions.each{|name,diminsions|
      info[name]=self.version_info(name)
    }
    info
  end

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

  def all_versions
    result={}
    self.full_versions.each{|v,d|
      result["#{I18n.t(:"image file.versions.#{v}")} (#{d})"]={:url=>self.url(v),:width=>self.width(v),:height=>self.height(v)}
    }
    result.each{|key,value|
      yield key,value,self
    }
  end
  def self.create_with_parent! parent,attributes={}
    if parent
      picture=Media::ImageFile.new(attributes.merge(:pictureable_type=>parent.class.to_s,:pictureable_id=>parent.id))
      picture.save!
      picture
    else
      raise "Nav norādīts vecāka objekts!"
    end
  end

  def self.new_from_params params={}
    file=self.new_file(params)
    file.main_image=params[:single]=="true" ? true : nil
    file
  end
    
  def next_picture
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("asc").after(self.position).first
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("asc").first unless picture
    picture
  end

  def prev_picture
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("desc").before(self.position).first
    picture=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).positioned("asc").last unless picture
    picture
  end

  def add_watermark(watermark,version=nil,dimensions=nil)
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
  def self.get_watermark
    if File.exist?(RAILS_ROOT+"/public/images/image_file_watermark.png")
      Magick::Image.read(RAILS_ROOT+"/public/images/image_file_watermark.png").first
    end
  end

  def add_watermarks
    if self.name && watermark54=Media::ImageFile.get_watermark
      self.full_versions.each{|version,dimensions|
        add_watermark(watermark54,version,dimensions)
      }
      self.toggle!(:watermark_added)
    end
  end

  def self.get_temp_destination
    timestamp="#{rand(100000)}"+Time.now.strftime("%Y%m%d%H%M%S")
    "#{RAILS_ROOT}/public/upload/#{self.to_s.underscore}/name/tmp/#{timestamp}"
  end

  def before_upload options={}
    versions_class=self.pictureable_type.constantize
    if versions_class.respond_to?(:upload_column_versions)
      c_versions=versions_class.upload_column_versions
      options[:versions].merge!(c_versions) if c_versions
    end
    options
  end
  private

  def singularize_main
    if @changed_attributes && @changed_attributes.has_key?('main_image') && self.main_image
      old_main=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).main.find(:first)
      old_main.update_attributes!(:main_image=>nil) if old_main
    end
  end
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

  def assign_position
    if (self.pictureable_id.to_i>0 && !self.position)
      current_position=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).maximum("position")
      current_position=current_position ? current_position+1 : 1
      self.position=current_position
    end
  end

  def all_siblings picture, options={}
    options={
      :sort=>"id asc"
    }.merge(options)
    Media::ImageFile.find(:all,:conditions=>["pictureable_type=? AND pictureable_id=?",self.pictureable_type,self.pictureable_id],:order=>options.sort)
  end
end
