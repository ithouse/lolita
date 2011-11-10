module Lolita
  module Adapter
    module AbstractAdapter
      abstract_method '',:fields,:db, :db_name,:collection,:collection_name,:collections,:collection_names
      abstract_method '',:associations,:associations_class_names
      abstract_method "value",:collection_name=
      abstract_method 'page,per,options ={}',:paginate
      abstract_method 'method_name,page,per,options', :pagination_scope_from_klass
      abstract_method 'name',:reflect_on_association,:field_by_name,:field_by_association
      abstract_method 'id',:find_by_id
      abstract_method 'query', :search
    end
  end
end