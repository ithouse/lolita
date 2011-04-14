require File.expand_path(File.dirname(__FILE__) + '/../simple_spec_helper')

describe Lolita::Navigation::Branch do
  let(:tree){Lolita::Navigation::Tree.new("test tree")}

  describe "attributes" do
    let(:branch){Lolita::Navigation::Branch.new}

    it "should have title" do
      branch.title="Pages"
      branch.title.should == "Pages"
    end

    it "should have default name" do
      branch.name.should match(/branch/)
    end

    it "should not have level when branch is not in tree" do
      branch.level.should be_nil
    end

    it "should have options, that may containe any values needed" do
      branch.options[:url]="/"
      branch.options[:url].should == "/"
    end

    it "should belongs to tree" do
      branch.tree.should be_nil
      lambda{
        branch.tree=Object.new
      }.should raise_error(ArgumentError)
    end

    context "relationships" do

      it "should have parent" do
        branch=tree.add(Object)
        branch.parent.should == tree.root
      end

      it "should have childern" do
        branch.append(Lolita::Navigation::Branch.new)
        branch.children.class.should == Lolita::Navigation::Tree
        branch.children.should have(1).item
      end

      it "should have siblings" do
        tree.add(Object)
        branch=tree.add(String)
        branch.siblings[:before].should_not be_nil
        branch.siblings[:after].should be_nil
      end
    end
  end

  describe "adding" do
    let(:new_branch){Lolita::Navigation::Branch.new}

    it "should append to existing branch" do
      new_branch.append(Lolita::Navigation::Branch.new)
      new_branch.append(Object)
      new_branch.append("Pages")
      new_branch.children.should have(3).items
    end

    it "should prepend to exsiting branch" do
      new_branch.append(Object)
      new_branch.prepend(String)
      new_branch.children.first.object.should == String
    end

    it "should add before and after branch" do
      branch=tree.add(Object)
      branch.before(Lolita::Navigation::Branch.new)
      branch.after(Object)
      branch.siblings.values.compact.should have(2).items
    end
  end

end