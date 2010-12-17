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
else
  require 'active_record'
  ActiveRecord::Base.establish_connection({ :database => ":memory:", :adapter => 'sqlite3', :timeout => 500 })
  ActiveRecord::Schema.define do
    create_table :posts, :force => true do |t|
      t.string :field_one
    end
    create_table :test_class2, :force => true do |t|
      t.string :field_one
    end
    create_table :pages,:force=>true do |t|
      t.string :name
    end
  end
  
  class Comment < ActiveRecord::Base
    belongs_to :test_class1, :class_name=>"Post"
  end
  class Post < ActiveRecord::Base
    has_many :pages
    include Lolita::Configuration
    lolita 
  end


  class Profile < ActiveRecord::Base
    include Lolita::Configuration
    lolita do
      
    end
  end
end