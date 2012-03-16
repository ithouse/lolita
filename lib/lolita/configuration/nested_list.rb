module Lolita
  class ParentNotAListError < ArgumentError ; end

  module Configuration
    
    class NestedList < Lolita::Configuration::List
      attr_accessor :parent,:association_name

      def initialize dbi,parent,options={},&block
        set_and_validate_dbi(dbi)
        set_list_attributes
        
        @parent = parent
        set_attributes(options)
        self.instance_eval(&block) if block_given?
        validate
      end

      # Returns association with given name from parent object DBI
      def association
        self.parent && self.parent.dbi.reflect_on_association(self.association_name)
      end

      # Return mapping that class matches dbi klass.
      def mapping
        if @mapping.nil?
          mapping_class = if self.association && self.association.macro == :one
            self.parent.dbi.klass
          else
            dbi.klass
          end 
          @mapping = Lolita::Mapping.new(:"#{mapping_class.to_s.downcase.pluralize}") || false
        end
        @mapping
      end

      # Return all parent object where first is self.parent and last is root list or column.
      def parents
        unless @parents
          @parents = []
          object = self
          while object.respond_to?(:parent) && object.parent
            @parents << object.parent
            object = object.parent
          end
        end
        @parents
      end

      def root
        parents.last
      end

      # Return Hash with key <em>:nested</em> thas is Hash with one key that is foreign key that links parent with this list.
      def nested_options_for(record)
        if self.parent
          association = self.association
          attr_name = [:one,:many_to_many].include?(association.macro) ? :id : association.key
          attr_value = if association.through? && record.send(association.through)
            record.send(association.through).id
          elsif association.macro == :one
            record.send(association.name).id
          else
            record.id
          end
          base_options = {
            attr_name => attr_value,
            :parent => self.root.dbi.klass.to_s,
            :path => self.parents.map{|parent| parent.is_a?(Lolita::Configuration::List) ? "l_" : "c_#{parent.name}"}
          }
          if association.macro == :many_to_many
            base_options.merge({
              :association => association.name
            })
          end
          {:nested => base_options}
        end
      end

      # Return how deep is this list, starging with 1.
      def depth
        self.parents.size
      end

      private

      def validate
        msg = "#{parent.class} must be kind of Lolita::Configuration::List or Lolita::Configuration::Column"
        raise(Lolita::ParentNotAListError, msg) unless [
          Lolita::Configuration::List,
          Lolita::Configuration::Column
        ].detect{|pattern| parent.kind_of?(pattern)}
      end
    end

  end
end