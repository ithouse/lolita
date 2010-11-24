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

  class Comment
    include Mongoid::Document
    field :body
    referenced_in :post
    referenced_in :profile
  end
  class Post
    include Mongoid::Document
    include Lolita::Configuration
    field :title
    field :body
    references_many :comments,:class_name=>"Comment"
    referenced_in :profile
    lolita
  end

  class Profile
    include Mongoid::Document
    include Lolita::Configuration
    field :name
    field :age
    field :genere
    references_many :posts
    references_many :comments
    references_many :preferences, :stored_as=>:array, :inverse_of=>:profiles
    embeds_one :address
    lolita do

    end
  end

  class Address
    include Mongoid::Document
    field :street
    field :city
    field :state
    field :post_code
    embedded_in :person, :inverse_of => :address
  end
  
  class Preference
    include Mongoid::Document
    include Lolita::Configuration
    field :name
    references_many :profiles, :stored_as=>:array, :inverse_of=>:preferences
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