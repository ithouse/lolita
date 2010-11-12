if ADAPTER=='mongoid'
  require 'mongoid'
  Mongoid.configure do |config|
    name = "lolita3_test"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.slaves = [
      Mongo::Connection.new(host, 27017, :slave_ok => true).db(name)
    ]
    #config.use_object_ids = true
    config.persist_in_safe_mode = false
  end

  class TestClass1
    include Mongoid::Document
    include Lolita::Configuration
    field :field_one
    lolita
  end

  class TestClass2
    include Mongoid::Document
    include Lolita::Configuration
    field :field_one
    lolita do

    end
  end
else
  require 'active_record'
  ActiveRecord::Base.establish_connection({ :database => ":memory:", :adapter => 'sqlite3', :timeout => 500 })
  ActiveRecord::Schema.define do
    create_table :test_class1, :force => true do |t|
      t.string :field_one
    end
    create_table :test_class2, :force => true do |t|
      t.string :field_one
    end
  end
  class TestClass1 < ActiveRecord::Base
    set_table_name :test_class1
    include Lolita::Configuration
    lolita 
  end

  class TestClass2 < ActiveRecord::Base
    set_table_name :test_class2
    include Lolita::Configuration
    lolita do
      
    end
  end
end