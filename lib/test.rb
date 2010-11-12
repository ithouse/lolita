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


#class A
#  include Enumerable
#  def initialize
#    @arr=[1,2]
#  end
#  def each
#    @arr.each{|el| yield el}
#  end
#
#  def method_missing(m,*args,&block)
#    @arr.__send__(m,*args,&block)
#  end
#end
#
#a=A.new()
#puts a.size

#lolita do
#  tab.extend(:default) do
#    field :name=>:virtual_attribute # paplašina taba laukus ar šo
#  end
#end
## check for default relations
#class Post
#  mount_uploader :image
#
#end
## Post automātiski tiek ielādēts tabs attēlu augšupielādei
#lolita do
#  tab :content=>:default #to know that first tab is content tab, when other tabs are given
#  tab do
#    builder RedTab
#    name "Saturs"
#    field do
#      name "title"
#      title "Nosaukums"
#      type TextField
#    end
#    field :name=>"title"
#  end
#  tab("Specia fields") do
#    field_set do
#      field :name=>"body"
#    end
#  end
#  tab("Files") do
#    content :files
#    builder FileUpload
#    preview false
#    file_list do
#      builder AdvancedFileList
#    end
#  end
#  tab("Images") do
#    content :images
#    builder ImageUpload
#    file_list false # no file list
#    # or default file list
#  end
#  tabs.exclude :metadata,:content # to exclude default tabs
#  tabs_exclude :content # or this syntax
#end

class K
  def m1

  end

  def initialize
    
  end
  def m2

  end

  private

  def p
    
  end
end
puts K.instance_methods(false)
