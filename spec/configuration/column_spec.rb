require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Column do
  let(:dbi){Lolita::DBI::Base.create(Post)}
  let(:column){Lolita::Configuration::Column.new(dbi,:col1)}
  let(:column_class){Lolita::Configuration::Column}
  
  
  it "should create new column with Hash attributes" do
    column=Lolita::Configuration::Column.new(dbi,:name=>"col1",:title=>"Col1",:type=>String)
    column.name.should == :col1
  end

  it "should create new column with Proc as block given" do
    p=Proc.new{
      name "col1"
      title "Col one"
      type String
    }
    column=Lolita::Configuration::Column.new dbi,&p
    column.type.should == String
  end

  it "should create new column with block given" do
    column=Lolita::Configuration::Column.new(dbi) do
      name "col1"
      title "Col one"
      type String
    end
    column.title.size.should > 0
  end

  it "should create new column when String or Symbol is given" do
    column=Lolita::Configuration::Column.new(dbi,:col1)
    column.name.should == :col1
    column=Lolita::Configuration::Column.new(dbi,"col2")
    column.name.should == :col2
  end
  
  it "should raise error when no name is provided for column" do
    lambda{
      Lolita::Configuration::Column.new(dbi) do
        title "Col one"
      end
    }.should raise_error(ArgumentError, "Column must have name.")
  end

  it "should allow to add formatter with block" do
    column.formatter do|value|
      "value #{value}"
    end
    column.formatter.with("1").should == "value 1"
  end

  it "should allow to add formatter as attribute" do
    column.type :float
    column.formatter = "%.3f"
    column.formatter.with(44.88).should == "44.880"
  end

  it "should allow to add formatter as attribute with Lolita::Support instance" do
    column.formatter = Lolita::Support::Formatter.new("%s")
    column.formatter.is_a?(Lolita::Support::Formatter::Rails).should be_false
    column.formatter = "%s"
    column.formatter.is_a?(Lolita::Support::Formatter::Rails).should be_true
  end

  it "should allow to add formatter as block with Lolita::Support instance" do
    column=Lolita::Configuration::Column.new(dbi) do
      name "col1"
      title "Col one"
      type String
      formatter Lolita::Support::Formatter.new("%s")
    end
    column.formatter.is_a?(Lolita::Support::Formatter::Rails).should be_false
    column=Lolita::Configuration::Column.new(dbi) do
      name "col1"
      title "Col one"
      type String
      formatter "%s"
    end    
    column.formatter.is_a?(Lolita::Support::Formatter::Rails).should be_true
  end

  it "should make default formater not defined" do
    column.formatter.with(1).should == 1
  end

  it "should set association for column if name matches any association name" do
    new_column = column_class.new(dbi,:comments)
    new_column.association.klass.should == Comment
  end

  describe "sublist" do

    it "should accept sublist" do
      new_column = column_class.new(dbi,:comments) do
        list do
          column :body
        end
      end
      new_column.list.should_not be_nil
    end

    it "should accept list for reflection fields without any specifict arguments" do
      expect{
        column_class.new(dbi,:comments) do
          list{}
        end
      }.not_to raise_error

      expect{
        column_class.new(dbi, :title) do
          list{}
        end
      }.to raise_error(Lolita::UnknownDBPError)
    end

    it "should accept sublist in any depth" do
      dbi = Lolita::DBI::Base.create(Category)
      new_column = column_class.new(dbi,:posts) do
        list do
          column :title
          column :comments do
            list do
              column :body
            end
          end
        end
      end

      new_column.list.columns.by_name(:comments).list.should_not be_nil
    end

  end

end

