
conf = YAML.load(open("#{RAILS_ROOT}/config/lolita.yml").read)
conf[RAILS_ENV].each_key do |name|
  eval "LOLITA_#{name.upcase} = conf[RAILS_ENV][\"#{name}\"]"
end

Globalize::Locale.set_base_language LOLITA_LANGUAGE_CODE
