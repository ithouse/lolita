module Lolita
  module Configuration
    class MyCustomCollectionField < Lolita::Configuration::CollectionField
      
        def initialize *args,&block
          super
          @type="my_custom_collection"
        end

    end
  end
end