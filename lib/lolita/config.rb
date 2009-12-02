class Hash
  def fetch_all(key)
    return [] if not self.has_key?(key)
    value = self.fetch(key)
    [ value ] + [ value ].fetch_all(key)
  end
end

class Array
  def fetch_all(key)
    self.find_all{|x| x.respond_to? :fetch_all} \
      .map{|x| x.fetch_all(key) } \
      .inject( [] ){|a,b| a + b }
  end
end

module Lolita
  class Config
    # Lolita's configuration tool
    # all configuration is in YAML file located config/lolita.yml
    # Lolita's config you can access via Lolita.config or $lolita_config
    # Example:
    #   ----YAML----
    #     production:
    #       foo:
    #         baz:
    #           one: 1
    #           two: 2
    #       gmail:
    #         key: 8349032809890zxczxc
    #   ----CODE----
    #   Lolita.config.foo :baz, :one
    #   > 1
    #   Lolita.config.foo
    #   > {'baz' => {'one' => 1, 'two' => 2}}
    #

    attr_accessor :conf

    def initialize
      yaml_root = YAML::parse_file("#{RAILS_ROOT}/config/lolita.yml")
      current_env = yaml_root.select("/.")[0].transform.keys.include?(RAILS_ENV) ? RAILS_ENV : 'development'
      self.conf = yaml_root.select("/#{current_env}")[0].transform.symbolize_keys!
    end

    def method_missing(key,*args)
      last_item = @conf[key.to_sym]
      unless last_item.nil?
        deepth = 0
        while args.length > deepth
          last_item = last_item[args[deepth].to_sym]
          unless last_item.nil?
            deepth += 1
          else
            break
          end
        end
      end if args.length > 0
      last_item
    end

    def update *args
      return false unless args.size > 1
      eval "self.conf#{args[0,args.size-1].collect{|a| "['#{a}']"}.join} = args[args.size-1]"
      true
    end

  end

  def config
    $lolita_config
  end
  module_function :config
end