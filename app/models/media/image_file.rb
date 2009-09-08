class Media::ImageFile < Media::FileBase
  require 'RMagick'
  set_table_name :media_image_files
  # attr_accessor :watermark_free
  belongs_to :pictureable, :polymorphic => true
  image_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now #vienīgā šaize var būt, ja mēneše pēdējā dienā 23:59:59 uploado
    "image_file/name/#{time.strftime("%Y_%m")}/#{inst.id}"
  },
    :versions => { #System
    :cropped=>"420x420",
    :thumb =>"124x124"
  }
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

  #######################SPECIĀLĀS FUNKCIJAS ###################################
  
  def add_watermarks
    #require 'RMagick'
    if File.exist?(RAILS_ROOT+"/public/images/watermark-54.png") && self.picture
      watermark54=Magick::Image.read(RAILS_ROOT+"/public/images/watermark-54.png").first
      # watermark36=Magick::Image.read(RAILS_ROOT+"/public/images/watermark-38.png").first
      # add_watermark(watermark54)
      Media::ImageFile.full_versions.each{|version,dimensions|
        add_watermark(watermark54,version,dimensions)
      }
      self.toggle!(:watermark_added)
    end
  end
  
  ##############################################################################
  def self.get_temp_destination
    timestamp="#{rand(100000)}"+Time.now.strftime("%Y%m%d%H%M%S")
    "#{RAILS_ROOT}/public/upload/picture/picture/picture/tmp/#{timestamp}"
  end
  
  def self.full_versions
    VERSIONS.merge(N_VERSIONS).merge(S_VERSIONS)
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
        path=p.picture.path
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

  def self.rebuild 
    #require 'RMagick'
    root="#{RAILS_ROOT}/public/upload/picture/picture"
    v=self.full_versions
    v_keys=v.keys
    last_name,base_name,dir="","",""
    m_versions=[]
    time=Time.now
    puts "Start Media::ImageFile rebuild! #{time.strftime("%Y.%m.%d %H:%M:%S")}"
    Find.find(root) do |path|
      if FileTest.directory?(path)
        if File.basename(path)[0] == ?.
          Find.prune       # Don't look any further into this directory.
        else
          if m_versions.size>0
            diff=v_keys-m_versions
            puts "#{dir}/#{base_name}" unless diff.empty?
            diff.each{|ver|
              main_img=::Magick::Image::read("#{dir}/#{base_name}").first
              g=v[ver]
              if g.match(/c/)
                g=g.gsub("c","")
                g=g.split("x")
                main_img.crop_resized!(g[0].to_i,g[1].to_i)
              else
                g=g.split("x")
                main_img.resize_to_fit!(g[0].to_i,g[1].to_i)
              end
              main_img.write("#{dir}/#{base_name.gsub(/(\.\w+)$/,"-#{ver}\\1")}")
              GC.start
            }
          end
          m_versions=[]
          parts=path.split("/")
          if !parts.last.match(/\d{4}_\d{2}/) && parts.last.match(/\d{2}/)
            base_name,last_name,dir="","",path
            puts "Reset #{path}"
          end
          next
        end
      else
        f_name=File.basename(path)
        if f_name.match(/-(\w+)\.\w+$/)
          cur=$1.to_sym
          if(v_keys.include?(cur))
            p_name=f_name.gsub(/(-#{cur})(\.\w+)$/,"\\2")
            if (base_name=="" || (p_name!=last_name && p_name.size>last_name.size)) #lai izbēgtu no tā ja bāzes fails saucas fails-[versija].jpg
              base_name=p_name
              last_name=base_name
            end
            m_versions<<cur
          end
        else
          base_name=f_name
        end
      end
    end
    etime=Time.now
    puts "End of rebuild! #{etime.hour-time.hour}:#{etime.min-time.min}:#{etime.sec-time.sec}"
  end
  
  def self.recreate(options={})
    
    p=self.find_by_id(options[:id])
    if p && VERSIONS.keys.include?(options[:version].to_sym)
      path=p.picture.send(options[:version]).path #ielasu ceļu lai zinātu kur rakstīt
      img=::Magick::Image::read(p.picture.path).first #ielasu bāzes attēlu
      chopped=chopped_image(p,img,options) #no tā izgriežu vajadzīgo daļu
      dimensions=VERSIONS[options[:version].to_sym] #iegūstu dimensijas
      if dimensions.include?("c") #nosaku vai kropot vai nē
        dimensions=dimensions.gsub("c","").split("x")
        chopped.crop_resized!(dimensions[0].to_i,dimensions[1].to_i) #kropoju
      else
        dimensions=dimensions.split("x")
        chopped.resize_to_fit!(dimensions[0].to_i,dimensions[1].to_i) #resaizoju
      end
      chopped.write(path) #uzrakstu jauno bildi pa virsu
      if File.exist?(RAILS_ROOT+"/public/images/watermark-54.png") 
        watermark54=Magick::Image.read(RAILS_ROOT+"/public/images/watermark-54.png").first
        p.add_watermark(watermark54,options[:version])
      end
      GC.start #novācu visu lieko
    end
    p ? p.version_info(options[:version]) : ""
  end

  def self.info(version)
    dimensions_in_parts(self::VERSIONS[version])
  end
  
  def self.versions_names
    self::VERSIONS.collect{|key,value| key}
  end

  def self.versions
    if block_given?
      self::VERSIONS.each{|key,value|
        yield key,dimensions_in_parts(value)
      }
    else
      result={}
      self::VERSIONS.each{|key,value|
        result[key]=dimensions_in_parts(value)
      }
      result
    end
  end

  def versions_info
    info={}
    VERSIONS.each{|name,diminsions|
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
    if self.picture and version
      Magick::Image.read(self.picture.send(version).path).first.columns
    else
      0
    end
  end

  def height(version)
    if self.picture and version
      Magick::Image.read(self.picture.send(version).path).first.rows
    else
      0
    end
  end

  def type
    ext=self.picture.path.match(/\.\w+$/)[0].to_s
    ext=ext.slice(1,ext.size)
    case ext
    when "jpg"
      "jpeg"
    else
      ext
    end
  end

  def url(version=nil)
    if self.picture
      if version
        self.picture.send(version).url
      else
        self.picture.url
      end
    else
      ""
    end
  end
  
  def all_versions
    {
      'Thumb (124x124)'=>{:url=>self.picture.thumb.url,:width=>124,:height=>124},
      'Media Thumb (220x150)'=>{:url=>self.picture.media_thumb.url,:width=>220,:height=>150}
    }.each{|key,value|
      yield key,value,self
    }
  end
  def self.create_with_parent! parent,attributes={}
    if parent
      picture=Media::ImageFile.new(attributes)
      picture.pictureable_type=parent.class.to_s
      picture.pictureable_id=parent.id
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
  
  def delete_pdf
    files=FileItem.find(:all,:conditions=>["fileable_type=? AND fileable_id=?",self.pictureable_type,self.pictureable_id])
    if files.respond_to?("each")
      files.each{|file|
        if File.basename(file.name.filename,File.extname(file.name.filename))==File.basename(self.picture.filename,File.extname(self.picture.filename))
          file.destroy()
          
        end
      }
    end
    
  end

  def self.update_temp_pictures(parent,ses_arr)
    ses_arr.collect{|id|
      if picture = self.find_by_id(id)
        picture.update_attributes!(:pictureable_type=>parent.class.to_s,:pictureable_id=>parent.id)
        picture
      end
    }.compact
  end
  def self.clear_temp_pictures()
    self.delete_all(["pictureable_type IS NULL AND pictureable_id IS NULL AND created_at<=?",1.day.ago])
  end

  def add_watermark(watermark,version=nil,dimensions=nil)
    # chopped.resize_to_fit!(dimensions[0].to_i,dimensions[1].to_i)
    url="#{RAILS_ROOT}/public/#{version ? self.picture.send(version).url : self.picture.url}"
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

  def before_upload options
    versions_class=self.pictureable_type.constantize
    if versions_class.respond_to?(:upload_column_versions)
      c_versions=versions_class.upload_column_versions
      options[:versions].merge!(c_versions) if c_versions
    end
  end
  private 

  def singularize_main
    if @changed_attributes && @changed_attributes.has_key?('main_image') && self.main_image
      old_main=Media::ImageFile.by_parent(self.pictureable_type,self.pictureable_id).main.find(:first)
      old_main.update_attributes!(:main_image=>nil) if old_main
    end
  end
  def self.chopped_image(p,img,options={})
    crop_img=::Magick::Image::read(p.picture.cropped.path).first #ielasu cropped bildi
    c_width=crop_img.rows
    c_height=crop_img.columns
    b_width=img.rows
    b_height=img.columns
    w_diff=b_width.to_f/c_width.to_f
    h_diff=b_height.to_f/c_height.to_f
    img.crop(options[:x].to_i*w_diff,options[:y].to_i*h_diff,options[:width].to_i*w_diff,options[:height].to_i*h_diff)
  end

  def self.dimensions_in_parts(size)
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
