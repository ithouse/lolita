require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Lolita::Navigation do
  
  describe "Tree" do
    let(:tree){Lolita::Navigation::Tree.new("test")}

    it "should create new navigation tree with name" do
      tree=Lolita::Navigation::Tree.new("Test tree")
      tree.name.should == "Test tree"
    end

    it "should raise error when name is not specified" do
      lambda{
        Lolita::Navigation::Tree.new
      }.should raise_error(ArgumentError)
    end

    it "should add branch with given arguments" do
      tree.add(Object,:append,:url=>"/mypath")
      tree.should have(1).branch
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
end