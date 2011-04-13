require File.expand_path(File.dirname(__FILE__) + '/../simple_spec_helper')

describe Lolita::Navigation::Tree do

  let(:tree){Lolita::Navigation::Tree.new("test")}

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

  describe "work with nodes" do
    it "should have root branch with level 0" do
      tree.root.should_not be_nil
      tree.root.level.should == 0
    end
  end

  context "#add" do
    it "should accept object, position and options" do
      tree.add(Object,:append,:url=>"/mypath")
      tree.should have(1).branch
    end
  end

  context "#each" do

    let(:empty_branch){Lolita::Navigation::Branch.new(Object,:url=>"/")}

    it "should iterate through all branches" do
      0.upto(3){|i|
        tree.add(Object,:append,:url=>"/#{i}",:name=>"branch#{i}")
      }
      tree.each_with_index do |branch,index|
        branch.name.should == "branch#{index}"
      end
    end

    it "should itereate in each level" do
      parent_branch=tree.root
      branch=empty_branch
      0.upto(5){|i|
        parent_branch.append(branch)
        parent_branch=branch
        branch=Lolita::Navigation::Branch.new(Object,:url=>"/")
      }
      level_counter=1
      tree.each_level do |branches,level|
        branches.should have(1).item
        level.should == level_counter
        level_counter+=1
      end
    end
  end

  it "should have callbacks" do
    Lolita::Navigation::Tree.should respond_to(:hooks)
    hook_names=[:before_load,:after_load,:before_branch_added,:after_branch_added]
    (Lolita::Navigation::Tree.hooks - hook_names).should be_empty
  end

  it "should have way to add branches based on earlier added branches" do
    tree.after_branch_added do
      self.each do |branch|
        if branch.resources.is_a?(Object)
          branch.append(Object,:url=>"/")
        end
      end
    end
    tree.add(Object,:append,:url=>"/mypath")
    tree.should have(2).branches
  end
end