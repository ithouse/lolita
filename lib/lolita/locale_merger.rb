require 'ya2yaml'
require 'zipruby'

class Lolita::LocaleMerger

  attr_reader :locales_zip, :locales_status, :yamls
  
  # Merges Rails locale files
  # <b>Don't use this class directly use Rake tasks insted:</b>
  #
  # * +rake lolita:locales:merge+ - merges all locales in +config/locales/+ folder
  # * +rake lolita:locales:status+ - dispalys the current status of locales, currently empty key locations
  # 
  # Initializes merger, give some data or it will load all your locales
  #
  # * +yamls_dir+ - String with directory of locales, without ending slash
  # * +locales+ - Array with available locales
  #  
  def initialize yamls_dir = nil, locales = nil
    @yamls_dir= yamls_dir || "#{RAILS_ROOT}/config/locales"
    @yamls    = sanitize_yamls Dir.glob("#{@yamls_dir}/**/**/*.yml")
    @locales  = locales || I18n.available_locales
    @log_data = []
    @locales_status = "#{RAILS_ROOT}/tmp/#{RAILS_ENV}_lolita_locale_status"
    @locales_zip    = "#{RAILS_ROOT}/tmp/#{RAILS_ENV}_lolita_locale.zip"
  end

  # Merges all +@yamls+
  def merge
    @yamls.each do |base_file|
      # collect all brothers and sisters
      siblings = {}
      @locales.each do |lang|
        fname = "#{File.dirname(base_file)}/#{lang}.yml"
        unless File.exist?(fname)
          open(fname, 'w+') do |f|
            f.write({lang.to_s => nil}.ya2yaml)
          end
        end
        siblings[lang] = fname
      end
      # merge
      siblings.each do |lang, current_file|
        current_yaml_root = YAML::parse_file(current_file)
        current_data = current_yaml_root.transform

        siblings.each do |sibling_lang, sibling_file|
          unless sibling_file == current_file
            sibling_yaml_root = YAML::parse_file(sibling_file)
            sibling_data = sibling_yaml_root.transform
            current_data[lang.to_s] = {} unless current_data[lang.to_s].is_a?(Hash)
            current_data[lang.to_s] = yaml_merge(
              current_data[lang.to_s], # what
              sibling_data[sibling_lang.to_s] || {}, # with who
              :blank_new_values => true,
              :overwrite => false,
              :locale_path => [lang],
              :level => 0
            )
          end
        end

        # save changes
        open(current_file, 'w') do |f|
          f.write current_data.ya2yaml # unicode aware
        end
      end
    end
  end

  # returns text with status of YAMLS, empty keys
  def status_report
    out = [""]
    @yamls.each do |base_file|
      # collect all brothers and sisters
      siblings = {}
      @locales.each do |lang|
        fname = "#{File.dirname(base_file)}/#{lang}.yml"
        siblings[lang] = fname if File.exist?(fname)
      end
      # merge
      siblings.each do |lang, current_file|
        current_yaml_root = YAML::parse_file(current_file)
        current_data = current_yaml_root.transform

        siblings.each do |sibling_lang, sibling_file|
          unless sibling_file == current_file
            sibling_yaml_root = YAML::parse_file(sibling_file)
            sibling_data = sibling_yaml_root.transform
            current_data[lang.to_s] = {} unless current_data[lang.to_s].is_a?(Hash)
            current_data[lang.to_s] = yaml_merge(
              current_data[lang.to_s], # what
              sibling_data[sibling_lang.to_s] || {}, # with who
              :blank_new_values => true,
              :overwrite => false,
              :locale_path => [lang],
              :level => 0
            )
          end
        end

        # if something to log show it
        unless @log_data.empty?
          out << "locales#{current_file.split("locales")[1]}"
          out << @log_data.join("\n") unless [:test,:cucumber].include? RAILS_ENV
        end
        @log_data = []
      end
    end
    out.join("\n") + "\n\n"
  end

  # idea from: http://www.gemtacular.com/gemdocs/cerberus-0.2.2/doc/classes/Hash.html
  # modified by Gacha
  #
  # Merges YAML Hash
  #   * +second+ - YAML as Hash
  #   * +options+
  #     * +blank_new_values+ - all new values will be blank strings
  #     * +overwrite+ - _(true|false)_, to overwrite or not existing keys
  #
  def yaml_merge(first, second, options = {})
    second.each_key do |k|
      if first[k].is_a?(Hash) && second[k].is_a?(Hash)
        first[k] = yaml_merge(first[k],second[k], update_options(options,k))
      elsif second[k].is_a?(Hash)
        first[k] = {}
        first[k] = yaml_merge(first[k],second[k], update_options(options,k))
      elsif first[k].is_a?(Array) && second[k].is_a?(Array) && first[k].sort != second[k].sort
        first[k] = first[k] | (options[:blank_new_values] ? second[k].collect{""} : second[k])
        first[k].reject!(&:blank?)
        first[k] << "" if first[k].empty?
      elsif second[k].is_a?(Array)
        first[k] = second[k].collect do |v2|
          options[:blank_new_values] ? "" : (v2.is_a?(Hash) ? yaml_merge({},v2, update_options(options,k)) : v2)
        end unless (options[:overwrite] == false && first.key?(k))
      else
        first[k] = options[:blank_new_values] ? "" : second[k] unless (options[:overwrite] == false && first.key?(k))
      end
      log "\t[E] #{options[:locale_path].join(".")}.#{k}" if (first[k].is_a?(String) && first[k].blank?) || (first[k].is_a?(Array) && first[k].reject(&:empty?).empty?)
    end
    first
  end

  # returns cached version of status_report
  def status_report_cached(t = 10.minutes)
    if File.exists?(@locales_status)
      if (Time.now - File.stat(@locales_status).mtime) > t
        write_and_return_status
      else
        open(@locales_status).read
      end
    else
      write_and_return_status
    end
  end

  # generates ZIP file with locales and status file in /tmp/<RAILS_ENV>_lolita_locale.zip
  def create_locale_zip
    File.delete(@locales_zip) if File.exists?(@locales_zip)
    Zip::Archive.open(@locales_zip, Zip::CREATE) do |ar|
      ar.add_buffer('status.txt', status_report_cached)
      Dir.glob(Dir.glob("#{@yamls_dir}/**/**/*.yml")).each do |path|
        unless path =~ /~$/
          new_path = "locales/" + (path != @yamls_dir ? path.split("#{File.basename(@yamls_dir)}/").last : "")
          if File.directory?(path)
            ar.add_dir(new_path)
          else
            ar.add_file(new_path, path)
          end
        end
      end
    end
  end

  # clones one locale to another
  def clone from, to
    @yamls.each do |yaml|
      old_file = yaml.gsub(/\/([A-Za-z\-]+)\.yml/,"/#{from}.yml")
      new_file = yaml.gsub(/\/([A-Za-z\-]+)\.yml/,"/#{to}.yml")
      if File.exist?(old_file)
        old_yaml_root = YAML::parse_file(old_file)
        old_data = old_yaml_root.transform
        new_data = {to.to_s => yaml_merge(
            {}, # what
            old_data[from.to_s], # with who
            :blank_new_values => false,
            :overwrite => false,
            :locale_path => [to.to_s],
            :level => 0
          )}
        open(new_file, 'w+') do |f|
          f.write new_data.ya2yaml # unicode aware
        end
      else
        log "[warn] File #{old_file} doesn't exists"
      end
    end
  end

  def log msg
    @log_data << msg
  end
  
  private

  def write_and_return_status
    str = status_report
    open(@locales_status,'w+') do |f|
      f.write(str)
    end
    create_locale_zip
    str
  end

  def update_options options, k
    options.merge({:locale_path => options[:locale_path].clone << k, :level => options[:level]+1})
  end

  # return Array with yamls, each dir contains only one yaml
  def sanitize_yamls yamls
    _yamls = []
    used_dirs = []
    yamls.each do |yaml|
      unless used_dirs.include?(File.dirname(yaml))
        used_dirs << File.dirname(yaml)
        _yamls << yaml
      end
    end
    _yamls
  end

end