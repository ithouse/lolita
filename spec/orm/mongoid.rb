Bundler.require(:mongoid)
Mongoid.load!(File.expand_path("../mongoid.yml", __FILE__), :test)
