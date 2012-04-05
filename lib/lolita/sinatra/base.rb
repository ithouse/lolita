require 'lolita/sinatra/routes'
Dir[File.join(Lolita.root,"sinatra_app","**","*.rb")].each do |file_name|
  require file_name
end