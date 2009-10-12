class Cms::Base < ActiveRecord::Base
  self.abstract_class = true
  
  class << self

    def cms_create_conditions_from(data)
      table_name=self.table_name
      conditions=[""]
      (self.column_names.collect{|cn| cn.to_sym} & (data.keys-[:action,:controller])).each{|valid_column|
        match_sign=data[valid_column].is_a?(Array) ? " IN " : "="
        conditions[0]<<"`#{table_name}`.`#{valid_column}`#{match_sign}(?)"
        conditions<<data[valid_column]
      }
      conditions
    end

    def exclude_array conditions=[],arr=[],column=nil,include=false
      conditions[0]||=""
      unless arr.empty?
        conditions[0]<<" AND #{self.table_name}.#{column || "id"} #{include ? "" : "NOT"} IN (?)"
        conditions<<arr
      end
      conditions
    end

    def include_array conditions=[],arr=[],column=nil
      exclude_array conditions,arr,column,true
    end

    def assing_polymorphic_result_to_object(object,result,association_name)
      self.reflections.each{|name,reflection|
        if(reflection.options && reflection.options[:as]==association_name)
          if(reflection.macro==:has_many)
            object.send("#{name}=",result)
          elsif(reflection.macro==:has_one)
            object.send("#{name}=",result[0])
          end
        end
      }
    end
    
    def join_symbols_to_string(joins,join_type="INNER JOIN")
      joins.collect{|join|
        if join.is_a?(Symbol)
          reflection=self.reflect_on_association(join)
          table_name=reflection.klass.table_name if reflection
          if table_name
            "#{join_type} #{table_name} ON #{table_name}.#{reflection.macro==:belongs_to ? "id" : "#{self.to_s.foreign_key}"}=#{self.table_name}.#{reflection.macro==:belongs_to ? "#{reflection.klass.to_s.foreign_key}" : "id"}"
          end
        elsif join.is_a?(String)
          join
        else
          nil
        end
      }.compact
    end
    
    def complex_sort sort_fields=[],allowed_fields=[]
      sort_columns,join_statements=[],[]
      sort_fields.each{|field|
        field_in_parts=field.to_s.split(" ") #novērš kļūdu situācijā, kad ir "field asc"
        field=field_in_parts[0] if field_in_parts.size>0
        if field.match(/_id$/) && (allowed_fields.nil? || allowed_fields.include?(field.to_sym))
          self.build_join_sql(field,:sortable=>true){|sort_column,join_sql|
            sort_columns<<"#{sort_column}" if sort_column && !sort_columns.include?(sort_column)
            join_statements<<"#{join_sql}" if join_sql && !join_statements.include?(join_sql)
          }
        else
          sort_columns<< "`#{self.table_name}`.`#{field}`#{field_in_parts[1] ? " #{field_in_parts[1]}" : ""}"
        end
      }
      return join_statements,sort_columns.blank? ? nil : sort_columns
    end

    def build_join_sql foreign_key,options={}
      default_options={:join_type=>"LEFT JOIN"}
      options.merge!(default_options)
      reflection_object=self.reflect_on_association(foreign_key.to_s.gsub(/_id$/,"").to_sym).klass
      j_sql="#{options[:join_type]} `#{reflection_object.table_name}` ON `#{self.table_name}`.`#{Mysql.quote(foreign_key)}`=`#{reflection_object.table_name}`.id"
      if options[:sortable]
        column=reflection_object.first_column_name("string")
        sort_column="`#{reflection_object.table_name}`.`#{column}`" if column
        if block_given?
          yield sort_column, j_sql
        else
          return sort_column,j_sql
        end
      else
        if block_given?
          yield j_sql
        else
          return j_sql
        end
      end
    end
    
    def controller_object controller=nil
      "#{controller}_controller".camelize.constantize
    end

    def controller_and_action_from_url url=""
      controller_parts=url.split("/")
      controller=controller_parts[0..1].join("/")
      action=(controller_parts.size==1 ? :index : controller_parts[2] || :index)
      return controller,action
    end
    
    def parent_class_collector possible_parents=[]
      possible_parents.collect{|parent|
        reflection=self.reflect_on_association(parent.to_s.gsub(/_id$/,"").to_sym)
        reflection && reflection.macro==:belongs_to ? reflection : nil
      }.compact
    end

    def parent_data_collector data=[]
      data.each{|reflection|
        parent=reflection.class_name.constantize
        columns=parent.content_columns
        yield "#{reflection.name}_id".to_sym,reflection.class_name,parent.find(:all).collect{|parent_row|
          [self.field_value_from_row(parent_row,columns),parent_row.id] #TODO need primary key
        }.compact
      }
    end

    def field_value_from_row row,columns,type=:string
      column=columns.detect{|col| col.type==type.to_sym}
      column ? row.send(column.name) : nil
    end
    #TODO vajag testus līdz šejienei
    #nav tas spicākais bet domāju ka darbojās savieno
    # vienu hash ar otru ai arī hash ar string vai string ar strgin var arī kāds būt nil
    # vai arī masīvus
    def cms_merge_conditions real_old_conditions=[],real_new_conditions=[], merge_name="AND"
      old_conditions=(real_old_conditions || []).dup
      new_conditions=(real_new_conditions || []).dup
      old_conditions= !old_conditions || old_conditions.to_s.size<1 ? [] : old_conditions
      new_conditions=!new_conditions || new_conditions.to_s.size<1 ? [] : new_conditions
      raise "Can't merge Hash with something else than Hash" if (new_conditions.is_a?(Hash) && !old_conditions.is_a?(Hash)) || (!new_conditions.is_a?(Hash) && old_conditions.is_a?(Hash))
      if old_conditions.is_a?(Hash) && new_conditions.is_a?(Hash)
        new_conditions=old_conditions.merge(new_conditions)
      else
        old_conditions=[old_conditions] if old_conditions.is_a?(String)
        new_conditions=[new_conditions] if new_conditions.is_a?(String)
        if old_conditions && !old_conditions.empty? && !new_conditions.empty?
          old_sql="(#{old_conditions.shift})"
          new_sql="(#{new_conditions.shift})"
          new_conditions=old_conditions+new_conditions
          new_conditions=["#{old_sql} #{merge_name} #{new_sql}"] + new_conditions
        end
      end
      new_conditions.empty? ? old_conditions : new_conditions
    end

    def first_column_name type="string"
      column=self.columns.detect{|c| c.type.to_s.include?(type)}
      column ? column.name : nil
    end

    def column_by_name name
      self.columns.detect{|column| column.name==name}
    end
    
    def per_page
      @per_page||=Lolita.config.system :items_per_page
      @per_page
    end

    def paginate options={}
      paginator=Lolita::Paginator.new(self,options)
      paginator.find_records
      paginator
    end

    def count(*params)
      params=self.before_find(params) if self.respond_to?("before_find",true)
      super
    end
    
    def find(*params)
      #params=params.is_a?(Array) ? params.first : params
      if self.respond_to?("before_find",true)
        params=self.before_find(params)
      end
      super
    end
  end
end

