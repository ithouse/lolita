Rails.application.routes.draw do 
   match '/lolita' => "lolita/info#index"
   match '/lolita/info/properties' => "lolita/info#properties"
end