require File.expand_path(File.dirname(__FILE__) + '/../simple_spec_helper')

describe Lolita::Navigation::Tree do

  context "#new" do
    it "should create new navigation tree with name" do
      tree=Lolita::Navigation::Tree.new("Test tree")
      tree.name.should == "Test tree"
    end

    it "should raise error when name is not specified" do
      lambda{
        Lolita::Navigation::Tree.new
      }.should raise_error(ArgumentError)
    end

  end

  let(:tree){Lolita::Navigation::Tree.new("test")}

  context "#add" do
    it "should accept object, position and options" do
      tree.add(Object,:append,:url=>"/mypath")
      tree.should have(1).branch
    end
  end

  context "#each" do
    let(:populated_tree){
      p_tree=Lolita::Navigation::Tre.new("populated tree")
      0.upto(3){|i|
        p_tree.add(Object,:append,:url=>"/#{i}",:name=>"branch#{i}")
      }
      p_tree
    }

    it "should iterate through all branches" do
      populated_tree.each_with_index do |branch,index|
        branch.name.should == "branch#{index}"
      end
    end
  end

  context "callbacks" do
    it "should respond to callback #before_load" do
      Lolita::Hooks.tree("test").before_load
    end
  end

  it "should add new branch when other branches meet some criteria " do
    tree.add(Object,:append,:url=>"/mypath")
    tree.each_branch do |branch|
      if branch.resource.is_a?(Object) 
        tree.append(Object,:url=>"/mypath2")
      end
    end
    tree.should have(2).branches
  end
end