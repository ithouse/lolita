module Lolita
  module Adapter
    module AbstractAdapter

      abstract_method '',:fields,:db, :db_name,:collection,:collection_name,:collections,:collection_names
      abstract_method '',:associations,:associations_class_names
      abstract_method 'opt={}',:paginate
      abstract_method 'name',:reflect_on_association
      abstract_method 'association',:association_macro,:association_class_name
    end
  end
end