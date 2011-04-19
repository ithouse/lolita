module Lolita
  module Navigation
    class Tree
      include Enumerable
      include Lolita::Hooks

      class<<self
        def remember(tree)
          @@trees||={}
          @@trees[tree.name.to_sym]=tree
        end

        def [](name)
          @@trees||={}
          @@trees[name]
        end
      end

      add_hooks :before_branch_added, :after_branch_added

      attr_reader :name,:root,:default_position,:branches,:parent

      def initialize(name)
        @name=name
        @default_possition=:append
        @branches=[]
      end

      def each 
        @branches.each do |branch|
          yield branch
          if branch.children.any?
            branch.children.each do |child|
              yield child
            end
          end
        end
      end

      def root?
        !parent
      end

      def method_missing method_name, *args
        @branches.send(method_name.to_sym,*args)
      end


      def append(*branch)
        adding_branch(*branch) do |fixed_branch|
          @branches<<fixed_branch
        end
      end

      def prepend(*branch)
        adding_branch(*branch) do |fixed_branch|
          @branches.unshift(fixed_branch)
        end
      end

      def after(given_branch,*other_branch) 
        index=get_branch_index(given_branch)

        adding_branch(*other_branch) do |fixed_branch|
          put_in_branches(fixed_branch,index)
        end
      end

      def before(given_branch,*other_branch)
        index=get_branch_index(given_branch)

        adding_branch(*other_branch) do |fixed_branch|
          put_in_branches(fixed_branch,index-1)
        end
      end

      def get_branch_index(given_branch)
        @branches.each_with_index{|branch,index|
          return index if given_branch==branch
        }
        raise ArgumentError, "Branch #{given_branch.inspect} not exists in #{self.inspect}"
      end

      def set_parent(new_parent)
        @parent=new_parent
      end
      
      private

      def adding_branch *branch
        self.run(:before_branch_added,*branch)
        fixed_branch=fix_branch(*branch)
        yield fixed_branch
        @last_branch=fixed_branch
        self.run(:after_branch_added,fixed_branch)
        fixed_branch
      end

      def fix_branch(*branch)
        unless branch[0].is_a?(Lolita::Navigation::Branch)
          options=branch.extract_options!
          Lolita::Navigation::Branch.get_or_create(*branch,options.merge(:tree=>self))
        else
          branch[0].tree=self
          branch[0]
        end
      end

      def put_in_branches branch,index
        before_part=@branches.slice(0,index+1) || []
        after_part=@branches.slice(index+1,@branches.size-index) || []
        @branches=before_part+[branch]+after_part
      end

    end
  end
end