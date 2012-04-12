class Lolita::RestController < Sinatra::Base
  set :views, Lolita.root + '/app/views/'
  enable :sessions

  include Kaminari::Helpers::SinatraHelpers
  helpers Lolita::Helpers
end