module Lolita
  module Navigation
    class Branch

      attr_accessor :name,:object
      attr_reader :level,:options,:tree,:parent
      attr_writer :title

      def initialize(*args)
        
        @options=args ? args.extract_options! : {}
        set_object(args||[])
        set_default_values
        assign_attributes_from_options
      end

      def method_missing method_name, *args
        if @options.keys.include?(method_name) || @options.keys.include?(method_name.to_s)
          @options[method_name] || @options[method_name.to_s]
        else
          super
        end
      end

      def title
        if @title && @title.respond_to?(:call)
          @title.call(self)
        else
          @title || self.object.to.model_name.human(:count=>2)
        end
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

      def self_with_children
        if block_given?
          yield self
          @children.each do |branch|
            yield branch
          end
        else
          [self]+@children.map{|b| b}
        end
      end

      def index
        self.tree.get_branch_index(self)
      end

      def subtree?
        self.children.branches.any?
      end

      def populate_url(view)
        self.options[:url] ||= calculate_url(view)
      end

      def calculate_url(view)
        if self.options[:url]
          self.options[:url]
        elsif self.object.is_a?(Lolita::Mapping)
          view.send(:lolita_resources_path, self.object)
        elsif self.options[:url].respond_to?(:call)
          self.options[:url].call(view,self)
        end
      end

      def first_url_in_subtree(view)
        if self.subtree?
          subtree_branch = self.subtree.branches.detect{|branch|
            branch.visible?(view)
          }
          subtree_branch.calculate_url(view) if subtree_branch
        end
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

      def active?(view)
        resource = view.respond_to?(:resource_class) ? view.send(:resource_class) : nil rescue nil
        request = view.send(:request)
        self_active = if self.object.is_a?(Lolita::Mapping) && self.object && self.object.to == resource
          true
        elsif self.options[:active].respond_to?(:call)
          self.options[:active].call(view,self)
        elsif self.options[:url]
          self.options[:url] == request.path
        end
        self_active || (self.children.any? && self.children.branches.detect{|c_branch| c_branch.active?(view)})
      end

      def visible?(view)
        self_visible = if self.object && self.object.respond_to?(:to)
          view.send(:can?,:read,self.object.to)
        elsif self.options[:visible]
          if self.options[:visible].respond_to?(:call)
            self.options[:visible].call(view,self,branch)
          else
            self.options[:visible]
          end
        else
          true
        end
        self_visible && (self.children.any? && self.children.visible?(view) || self.children.empty?)
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
          else
            self.options[key] = value
          end
        }
      end
    end
  end
end