module Lolita
  module Navigation
    class Branch

      attr_accessor :title,:name,:object
      attr_reader :level,:options,:tree,:parent

      def initialize(*args)
        
        @options=args ? args.extract_options! : {}
        set_object(args||[])
        set_default_values
        assign_attributes_from_options
      end

      def tree=(new_tree)
        raise ArgumentError, "Tree already assigned" if self.tree || !new_tree.is_a?(Lolita::Navigation::Tree)
        @tree=new_tree
      end

      def children
        unless @children
          tree=Lolita::Navigation::Tree.new("#{name}_children_tree")
          tree.set_parent(self)
          @children=tree
        end
        @children
      end

      def index
        self.tree.get_branch_index(self)
      end

      def siblings
        index=self.index
        {
          :before=>self.tree.branches[index-1],
          :after=>self.tree.branches[index+1]
        }
      end

      def append(*args)
        move_to(:append,*args)
      end

      def after(*args)
        move_to(:after,*args)
      end

      def before(*args)
        move_to(:before,*args)
      end

      def prepend(*args)
        move_to(:prepend,*args)
      end

      def self.get_or_create(*args)
        options=args ? args.extract_options! : {}
        args||=[]
        possible_object=args[0]

        if possible_object.is_a?(String)
          self.new(possible_object,options.merge(:title=>possible_object))
        elsif possible_object.is_a?(self)
          possible_object
        else
          self.new(possible_object,options)
        end
      end

      def get_or_create(*args)
        self.class.get_or_create(*args)
      end

      private

      def move_to(position,*args)
        branch=get_or_create(*args)
        raise ArgumentError("Can't #{position} without branch.") unless branch
        if [:before,:after].include?(position) && !branch.tree
          raise ArgumentError, "Can't move in not-existing tree!"
        end
        new_branch=case position
        when :append
          self.children.append(branch)
        when :prepend
          self.children.prepend(branch)
        when :after
          branch.tree.before(branch,self)
        when :before
          branch.tree.after(branch,self)
        end
        new_branch.instance_variable_set(:"@level",new_branch.level+([:append,:prepend].include?(position) ? 1 : 0))
        new_branch
      end


      def set_object(args)
        @object=if args[0].is_a?(Lolita::Navigation::Tree)
          @level=0
          args[0]
        else
          args[0]
        end
      end

      def set_default_values
        @name||="branch_#{self.__id__}"
        @level||=0
      end

      def assign_attributes_from_options
        @options.each{|key,value|
          if self.respond_to?(:"#{key}=")
            self.send(:"#{key}=",@options.delete(key))
          end
        }
      end
    end
  end
end