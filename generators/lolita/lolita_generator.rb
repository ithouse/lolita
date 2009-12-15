class LolitaGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.file "lolita.yml", "config/lolita.yml"
      m.file "public.js", "public/javascripts/public.js"
      m.file "start_lolita.rb", "config/initializers/start_lolita.rb"
      m.file "tinymcestyle.css", "public/stylesheets/tinymcestyle.css"
    end
  end
end
