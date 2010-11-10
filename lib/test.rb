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


class A
  include Enumerable
  def initialize
    @arr=[1,2]
  end
  def each
    @arr.each{|el| yield el}
  end

  def method_missing(m,*args,&block)
    @arr.__send__(m,*args,&block)
  end
end

a=A.new()
puts a.size


