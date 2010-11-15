module Lolita
  module Adapter
    module AbstractAdapter

      abstract_method '',:fields,:db, :db_name,:collection,:collection_name,:collections,:collection_names
      abstract_method 'opt={}',:paginate
    end
  end
end