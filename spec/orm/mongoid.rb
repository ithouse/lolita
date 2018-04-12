Bundler.require(:mongoid)
puts File.expand_path("../mongoid.yml", __FILE__)
Mongoid.load!(File.expand_path("../mongoid.yml", __FILE__), :test)
