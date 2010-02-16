require 'ya2yaml'

class ::Hash
  # idea from: http://www.gemtacular.com/gemdocs/cerberus-0.2.2/doc/classes/Hash.html
  # modified by Gacha
  #
  # Merges YAML Hash
  #   * +second+ - YAML as Hash
  #   * +options+
  #     * +blank_new_values+ - all new values will be blank strings
  #     * +overwrite+ - _(true|false)_, to overwrite or not existing keys
  #
  def yaml_merge!(second, options = {})
    second.each_key do |k|
      if self[k].is_a?(Hash) && second[k].is_a?(Hash)
        self[k].yaml_merge!(second[k], options)
      elsif second[k].is_a?(Hash)
        self[k] = {}
        self[k].yaml_merge!(second[k], options)
      elsif self[k].is_a?(Array) && second[k].is_a?(Array) && self[k].sort != second[k].sort
        self[k] = self[k] | (options[:blank_new_values] ? second[k].collect{""} : second[k])
        self[k].reject!(&:blank?)
        self[k] << "" if self[k].empty?
      elsif second[k].is_a?(Array)
        self[k] = second[k].collect do |v2|
          options[:blank_new_values] ? "" : (v2.is_a?(Hash) ? {}.yaml_merge!(v2, options) : v2)
        end unless (options[:overwrite] == false && self.key?(k))
      else
        self[k] = options[:blank_new_values] ? "" : second[k] unless (options[:overwrite] == false && self.key?(k))
      end
    end
  end
end

class Lolita::LocaleMerger
  # Merge Rails locale files

  # Initializes merger, give some data or it will load all your locales
  #
  # * +yamls+ - Array with locale files
  # * +locales+ - Array with available locales
  #
  def initialize yamls = nil, locales = nil
    @yamls    = yamls || Dir.glob("#{RAILS_ROOT}/config/locales/**/**/*.yml")
    @locales  = locales || I18n.available_locales
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
            current_data[lang.to_s].yaml_merge!(sibling_data[sibling_lang.to_s] || {}, :blank_new_values => true, :overwrite => false)
          end
        end

        # save changes
        open(current_file, 'w') do |f|
          f.write current_data.ya2yaml # unicode aware
        end
        
      end
    end
  end
end