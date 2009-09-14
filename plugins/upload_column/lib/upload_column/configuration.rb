module UploadColumn
  
  mattr_accessor :configuration, :image_column_configuration, :audio_column_configuration, :video_column_configuration, :extensions, :image_extensions, :audio_extensions, :video_extensions
  
  self.extensions = %w(asf ai avi doc docx dvi dwg eps gif gz jpg jpeg mov mp3 mpeg odf pac pdf png ppt psd swf swx tar tar.gz torrent txt wmv wav xls zip xlsx docx pptx rar odt ods odp odg)
  self.image_extensions = %w(jpg jpeg gif png)
  self.audio_extensions = %w(mp3 m3u wma wax wav ogg oga)
  self.video_extensions = %w(swf mpeg mov avi asf wmv ogv oga ogx ogg)
  
  DEFAULT_CONFIGURATION = {
    :tmp_dir => 'tmp',
    :store_dir => proc{ |r, f| f.attribute.to_s },
    :root_dir => File.join(RAILS_ROOT, 'public','upload'),
    :temp_root_path=>File.join(RAILS_ROOT,"tmp"), #Artūrs Meisters added
    :get_content_type_from_file_exec => true,
    :fix_file_extensions => false,
    :process => nil,
    :permissions => 0644,
    :extensions => self.extensions,
    :web_root => '',
    :manipulator => nil,
    :versions => nil,
    :quality=>nil, # Can write {:thum=>55}
    :strip=>nil, # Can be true, false or nil
    :validate_integrity => false
  }
  
  self.configuration = UploadColumn::DEFAULT_CONFIGURATION.clone
  self.image_column_configuration = {
    :manipulator => UploadColumn::Manipulators::RMagick,
    :root_dir => File.join(RAILS_ROOT, 'public', 'upload'),
    :web_root => '/upload',
    :extensions => self.image_extensions
  }.freeze
  # added by Gatis Tomsons
  self.audio_column_configuration = {
    :manipulator => nil,
    :root_dir => File.join(RAILS_ROOT, 'public', 'upload'),
    :web_root => '/upload',
    :extensions => self.audio_extensions
  }.freeze
  
  self.video_column_configuration = {
    :manipulator => nil,
    :root_dir => File.join(RAILS_ROOT, 'public', 'upload'),
    :web_root => '/upload',
    :extensions => self.video_extensions
  }.freeze
  #-----------------------
  
  def self.configure
    yield ConfigurationProxy.new
  end
  
  def self.reset_configuration
    self.configuration = UploadColumn::DEFAULT_CONFIGURATION.clone
  end
  
  class ConfigurationProxy  
    def method_missing(method, value)
      if name = (method.to_s.match(/^(.*?)=$/) || [])[1]
        UploadColumn.configuration[name.to_sym] = value
      else
        super
      end
    end
  end
  
end