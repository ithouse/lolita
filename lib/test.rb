#require "#{File.join(File.dirname(__FILE__),'lolita.rb')}"
#puts "Starting"
#class Person
#  include Mongoid::Document
#  field :first_name
#  field :middle_initial
#  field :last_name
#  field :birth_date, :type=>DateTime
#  field :live, :type=>Boolean
#  field :description
#  lolita_config
#end
#
#puts Person.ancestors.inspect
#puts Person.lolita_config.list.columns.inspect

require 'mongoid'
class A
  include Mongoid::Document
end

module M

end
class K < A
  include M
  include Enumerable
  def initialize(a,b)
    @arr=[a,b]
  end

  def each
    @arr.each{|el| yield el}
  end
end
puts K.ancestors
k=K.new(*[1,2])



