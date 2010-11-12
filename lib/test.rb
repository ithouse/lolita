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
Mongoid.master.collections.select do |collection|
  collection.name !~ /system/
end.each(&:drop) 

class Person
  include Mongoid::Document
  field :name
  references_one :policy
  references_many :prescriptions
  references_many :preferences, :stored_as => :array, :inverse_of => :people
end

class Policy
  
  include Mongoid::Document
  field :name
  referenced_in :person
end

class Prescription
  
  include Mongoid::Document
  field :name
  referenced_in :person
end

class Preference
  include Mongoid::Document
  field :name
  references_many :people, :stored_as => :array, :inverse_of => :preferences
end
person = Person.create(:name=>"vards")
policy = Policy.create(:name=>"policy_name")
prescription = Prescription.create(:name=>"prescription_name")
preference=Preference.create(:name=>"preference_name")

person.policy = policy
person.prescriptions = [prescription]
person.preferences=[preference]

puts Person.collection.db.name
puts Person.collection.inspect
#puts Mongoid::master.collections.inspect
puts Person.fields.inspect
puts person.preferences.inspect

