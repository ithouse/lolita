# Common class methods for #Lolita models. Controller that are subclass of #Managed
# it related model should be subclass of #Cms::Base.
class Cms::Base < ActiveRecord::Base
  self.abstract_class = true
  
  class << self

    # Create ActiveRecord::Base#find like conditions Array from given +data+ Hash.
    # Exclude from data <code>:controller</code> and <code>:action</code> values.
    # Values of +data+ Hash can be Array or any single value type variable (e.g. String, Integer).
    # ====Example
    #     class Comment < Cms::Base
    #       def self.create_filter
    #        self.find(:all,:conditions=>self.cms_create_conditions_from({:user_id=>[1,2],:total_views=>10})
    #        #=> ["`comments`.`user_id` IN (?) AND `comments`.`total_views`=10"]
    #       end
    #     end
    def cms_create_conditions_from(data, logical_operator="AND")
      table_name=self.table_name
      conditions=[""]
      (self.column_names.collect{|cn| cn.to_sym} & (data.keys-[:action,:controller])).each{|valid_column|
        match_sign=data[valid_column].is_a?(Array) ? " IN " : "="
        conditions[0]<<"`#{table_name}`.`#{valid_column}`#{match_sign}(?) #{logical_operator} "
        conditions<<data[valid_column]
      }
      conditions
    end

    # Add to +conditions+ field filter for +column+ (default 'id') and filter it from +arr+ data,
    # when +include+ is set to True then include +arr+ values otherwise exclude.
    # ====Example
    #     # for Comments model
    #     exclude_array(["text LIKE ?",'%text'],[1,2,3],'user_id',true) #=>
    #     ["text LIKE ? AND `comments`.`user_id` IN (?)",'%text',[1,2,3]]
    def exclude_array conditions=[],arr=[],column=nil,include=false
      conditions[0]||=""
      unless arr.empty?
        conditions[0]<<" AND #{self.table_name}.#{column || "id"} #{include ? "" : "NOT"} IN (?)"
        conditions<<arr
      end
      conditions
    end

    # Same as #exclude_array only force last of arguments of that method be true.
    def include_array conditions=[],arr=[],column=nil
      exclude_array conditions,arr,column,true
    end

    # Method refresh AR +object+ +assciation_name+ with new +result+ data of
    # some calculation. Checks if current object has that kind of reflection and what
    # kind of macro it uses for correctly assign result to it.
    # Important! +Result+ always need to be Array.
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

    # Recreate +joins+ Array by replacing Symbol type elements with String type or simply excluding it
    # when it has other type. Any Symbol type variable will be replaced with SQL join statement that
    # starts with +join_type+. Join SQL statements are created from reflections and will work only on
    # one-to-many relations, either current class belongs to other or other to current.
    # ====Example
    #     class User < Cms::Base
    #       has_many :comments
    #     end
    #
    #     class Comment < Cms::Base
    #       belons_to :user
    #     end
    #     # Calling method from Comment model.
    #     join_symbols_to_string([:user])#=>
    #     ["INNER JOIN users.id=comments.user_id"]
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

    # Used in #Managed. Create SQL join statements if required and create sort statement.
    # Receive +sort_fields+ Array of sort columns and +allowed_fields+ for specifying fields that
    # should be used for sorting.
    # When complex sort find field that ends with <code>_id</code> than it try to create join statement
    # and include first foreign String type fields in SQL results otherwise simply add sort field to result Array.
    # ====Example
    #     # for Comment model, in user table has id|login|passwod columns
    #     complex_sort(["user_id ASC"])#=>
    #     ["LEFT JOIN users ON comments.user_id=users.id"], ["users.login ASC"]
    def complex_sort sort_fields=[],allowed_fields=[]
      sort_columns,join_statements=[],[]
      sort_fields.each{|field|
        field_in_parts=field.to_s.split(" ") 
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

    # Used by #complex_sort. Create join statement and sort column if needed.
    # Receiving +foreign_key+ and finding form reflections related object and from that
    # related table name and columns.
    # +Options+ are allowed:
    # * <tt>:join_type</tt> - SQL join type, default "LEFT JOIN"
    # * <tt>:sortable</tt> - Create sort statement for first foreign table String type column, return only join statements when this options is set to true.
    # Method can be called with or without block.
    # Method return join statement and sort statement if :sortable options specified
    # or join statement if not, or nothing if no reflection found.
    def build_join_sql foreign_key,options={}
      default_options={:join_type=>"LEFT JOIN"}
      options.merge!(default_options)
      reflection=self.reflect_on_association(foreign_key.to_s.gsub(/_id$/,"").to_sym)
      if reflection
        reflection_object=reflection.klass
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
    end

    # Return controller object from given name or raises error.
    # ====Example
    #     controller_object("user") #=> UserController
    def controller_object controller=nil
      "#{controller}_controller".camelize.constantize
    end

    # Return Array of reflections from +possible_parrents+ Array.
    # When +possible_parents+ element is reflection of self class and is :belong_to
    # reflection that it is included in result otherwise not.
    def parent_class_collector possible_parents=[]
      possible_parents.collect{|parent|
        reflection=self.reflect_on_association(parent.to_s.gsub(/_id$/,"").to_sym)
        reflection && reflection.macro==:belongs_to ? reflection : nil
      }.compact
    end

    # Receive +data+ Array where each element is reflection and yields reflection field, class, data of arrays
    # Method can be called only with block. For data details see #field_value_from_row
    # ====Example
    #     # User model has only one reflection has_many :comments
    #     parent_data_collector([User.reflections[0]]) do |foreign_column, class_name, data|
    #       foreign_column #=> "comments_id", Comment, []
    #     end
    def parent_data_collector data=[]
      data.each{|reflection|
        parent=reflection.class_name.constantize
        columns=parent.content_columns
        yield "#{reflection.name}_id".to_sym,reflection.class_name,parent.find(:all).collect{|parent_row|
          [self.field_value_from_row(parent_row,columns),parent_row.id] #FIXME need primary key
        }.compact
      }
    end

    # Return +row+ (ActiveRecord object) with given +columns+ finding given +type+
    # column and if found return this field value otherwise NIL.
    def field_value_from_row row,columns,type=:string
      column=columns.detect{|col| col.type==type.to_sym}
      column ? row.send(column.name) : nil
    end

    # Find first column name with given +type+.
    def first_column_name type="string"
      column=self.columns.detect{|c| c.type.to_s.include?(type)}
      column ? column.name : nil
    end

    # Find first column with given +name+.
    def column_by_name name
      self.columns.detect{|column| column.name==name}
    end

    # Return and set default per page items count.
    def per_page
      @per_page||=Lolita.config.system :items_per_page
      @per_page
    end

    # Paginate self records by receiving +options+ and passing to #Lolita::Paginator
    # Create new paginators and find records and return paginator.
    def paginate options={}
      paginator=Lolita::Paginator.new(self,options)
      paginator.find_records
      paginator
    end

    # Very simple methods chainging, if class has <code>before_find</code> method
    # than call it before calling #ActiveRecord::Base count method.
    # Method can modify +params+ so real count method can use new.
    def count(*params)
      params=self.before_find(params) if self.respond_to?("before_find",true)
      super
    end

    # Call class <code>before_find</code> method before calling #ActiveRecord::Base find method.
    # Before find method can modify +params+ to real find can use them.
    def find(*params)
      #params=params.is_a?(Array) ? params.first : params
      if self.respond_to?("before_find",true)
        params=self.before_find(params)
      end
      super
    end
  end
end

