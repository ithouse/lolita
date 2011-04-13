module Lolita
  module Navigation

    class Tree
      include Lolita::ObservedArray

      def initialize
        @branches=[]
      end

      private

      def collection_variable
        @branches
      end

      def build_element element,*args
        if element.is_a?(Lolita::Navigation::Branch)
          element
        else
          Lolita::Navigation::Branch.new(*args)
        end
      end
    end #base class end

    # 
    # c_branch=Branch.new(:category)
    # c_branch.mapping == Lolita.mappings[:category] #=>true
    # c.branch.resource == Lolita.mappings[:category].to #=>true
    # Branch.new(:page, :path=>{:action=>:new},:after=>Navigation.by_name(:category,:level=>1))
    # Branch.new(:user,:prepend=>Navigation.root || {:level=>0} || 0)
    # Branch.new(
    #   Proc.new{|resource| resource.lolita.reports.by_name("statistic")},
    #   :append=>Navigation.by_name(:category,:level=>1),
    #   :path=>{:action=>:report,:plural=>true}
    # )
    class Branch
      attr_reader :name

      def initialize(*args)
        options=args.extract_options!
        @name=args.first

      end
    end #branch class end

  end
end