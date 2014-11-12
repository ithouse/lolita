Rails.application.routes.draw do 
   match '/lolita' => "lolita/info#index", via: [:get]
   match '/lolita/info/properties' => "lolita/info#properties", via: [:get]
   match "/lolita/array_field/:name/:field_class/:class/:id" => "lolita/field_data#array_polymorphic", :as => "array_field_data_collector", via: [:get]
	 match "/lolita/autocomplete_field/:field_class/:field_name" => "lolita/field_data#autocomplete_field", :as => "autocomplete_field", via: [:get]
end
