Rails.application.routes.draw do 
   match '/lolita' => "lolita/info#index"
   match '/lolita/info/properties' => "lolita/info#properties"
   match "/lolita/array_field/:name/:field_class/:class/:id" => "lolita/field_data#array_polymorphic", :as => "array_field_data_collector"
end