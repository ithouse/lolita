module Lolita
  module Adapter
    module CommonHelper

      class Record
        def initialize(adapter,orm_record)
          @adapter = adapter
          @record = orm_record
        end

        def title
          if @record.respond_to?(:title)
            @record.title
          elsif @record.respond_to?(:name)
            @record.name
          elsif content_field = @adapter.fields.detect{|f| f.type.to_s=="string"}
            @record.send(content_field.name)
          else
            "#{@record.class.respond_to?(:model_name) ? @record.class.model_name.human : @record.class} #{@record.id}"
          end
        end
      end

      def record(orm_record)
        Record.new(self,orm_record)
      end

      # Return all association class names
      def associations_class_names
        self.associations.map{|name,association|
          association.class_name
        }
      end

      def association_by_klass(given_klass)
        associations.select{|name,association|
          association.klass == given_klass
        }.values.first
      end

      def filter attributes={}
        klass.where(attributes.reject{|k,v| v.blank? })
      end

      # Detect if class reflect on association by name
      def reflect_on_association(name)
        if orm_association = klass.reflect_on_association(name)
          self.class.const_get(:Association).new(orm_association,self)
        end
      end

      def by_id(id)
        klass.where(klass.primary_key => id)
      end

      def find_by_id(id)
        self.klass.unscoped.merge(by_id(id)).first
      end

      def nested_scope_from_hash(hsh)
        nested_hsh ||= (hsh[:nested] || {})
        unless nested_hsh[:association]
          nested_hsh = nested_hsh.reject{|k,v| [:parent,:path].include?(k.to_sym)}
          criteria = klass.where(nested_hsh)
          criteria
        end
      end

      def scope_from_hash(hsh)
        if hsh[:nested] && hsh[:nested][:association]
          klass.find_by_id(hsh[:nested][:id]).send(hsh[:nested][:association])
        end
      end

      # This method is used to paginate, main reason is for list and for index action. 
      # Method accepts three arguments
      # <tt>page</tt> - page that should be shown (integer)
      # <tt>per</tt> - how many records there should be in page
      # <tt>options</tt> - Hash with optional information. 
      # By default, Lolita::Configuration::List passes request, with current request information.
      # Also it passes <i>:pagination_method</i> that is used to detect if there is special method(-s) in model
      # that should be used for creating page.
      def paginate(page,per,options ={})
        criteria = options[:request].respond_to?(:params) && nested_scope_from_hash(options[:request].params) || {}
        scope = options[:request].respond_to?(:params) && scope_from_hash(options[:request].params) || klass.unscoped
       
        if options[:pagination_method]
          if options[:pagination_method].respond_to?(:each)
            options[:pagination_method].each do |method_name|
              options[:previous_scope] = scope
              if new_criteria = pagination_criteria_for_klass(method_name,page,per,options)
                criteria = criteria ? criteria.merge(new_criteria) : new_criteria
              end
            end
          else
            criteria = pagination_scope_for_klass(options[:pagination_method],page,per,options)
          end
          raise ArgumentError, "Didn't generate any scope from #{options} page:{page} per:#{per}" unless criteria
          criteria
        else
          scope.merge(criteria).page(page).per(per)
        end
      end

      def pagination_scope_for_klass(method_name,page,per,options)
        if klass.respond_to?(method_name)
          klass.send(method_name,page,per,options)
        end
      end

      def switch_record_state(record, state = nil)
        set_state_for(record)
        if state
          record.send(:"#{state}_state!") 
        elsif !record.have_state?
          if record.new_record?
            record.create_state!
          else 
            record.update_state!
          end
        end
        record
      end
      
      def set_state_for(record)
        unless record.respond_to?(:read_state!)
          class << record

            def set_state(new_state)
              @state_set = true
              @state = new_state
            end

            def have_state?
              @state_set
            end

            def read_state!
              set_state :read
            end

            def create_state!
              set_state :create
            end

            def update_state!
              set_state :update
            end

            def state
              set_state(:read) unless @state
              @state
            end

            def in_read_state?
              state == :read
            end

            def in_create_state?
              state == :create
            end

            def in_update_state?
              state == :update
            end
          end
        end
        record
      end

    end
  end
end