module Lolita
  module Filters #:nodoc:
    # Manage advanced filter. Filter data, create SQL conditions and provide
    # #Lolita::Filters::AdvancedFilterHelper with data about model fields and field types
    # and editor type of field to filter data based on that field.
    # For detail use of filter see #Lolita::Paginator.
    # ====Example
    #     # Simplest use of advanced filter
    #     class User < ActiveRecord::Base
    #       advanced_filter
    #     end
    #
    module AdvancedFilter
      if not Object.constants.include? "ADVANCED_FILTER_CONDTIONS"
        ADVANCED_FILTER_CONDITIONS={
          "greater"=>"&gt;",
          "same"=>"=",
          "smaller"=>"&lt;",
          "like"=>"&asymp;",
          "greater_or_same"=>"&ge;",
          "smaller_or_same"=>"&le;",
          "not_same"=>"&ne;"
        }
      end
      if not Object.constants.include? "SINGLESIGN"
        SINGLESIGN={
          "greater"=>">",
          "same"=>"=",
          "smaller"=>"<",
          "like"=>" LIKE ",
          "greater_or_same"=>">=",
          "smaller_or_same"=>"<=",
          "not_same"=>"!="
        }
      end
      if not Object.constants.include? "MULTISIGN"
        MULTISIGN={
          "greater"=>" NOT IN ",
          "same"=>" IN ",
          "smaller"=>" NOT IN ",
          "like"=>" IN ",
          "greater_or_same"=>" NOT IN ",
          "smaller_or_same"=>" NOT IN ",
          "not_same"=>" NOT IN "
        }
      end
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end
      # Methods available in ActiveRecord::Base classes.
      module ClassMethods
        @@advanced_filter_allowed_keys=[:conditions,:include,:select,:limit,:offset,:group,:order,:joins,:from]

        # Points that class uses AdvancedFilter for filtering by default
        # when listing model data.
        # Method expects object as only argument, by default it is NIL.
        def advanced_filter obj=nil
          @object=obj
          @has_advanced_filter=true
          @last_filter=self.default_filter_data_hash
          include Lolita::Filters::AdvancedFilter::InstanceMethods
          extend Lolita::Filters::AdvancedFilter::ClassMethods #FIXME why need this
        end

        # Determine whether class uses AdvancedFilter.
        def has_advanced_filter?
          @has_advanced_filter
        end

        # Return current used filter id on NIL.
        def loaded_advanced_filter
          current_filter ? current_filter.id  :  nil
        end

        # Return all current object advanced filters as a collection of #Lolita::Filters::AdvancedFilter::Filter objects.
        def advanced_filters
          Filter.find(:all,:conditions=>["class_name=?",filter_object.to_s]) || []
        end

        # Set current user ID. User id is used to use filters specific for every user.
        def set_user(user)
          @user_id=user
        end
        
        # Return collection of filter name and id for HTML select.
        # ====Example
        #     advanced_filter_for_options #=> [[filter1, 1],[filter2, 2]]
        def advanced_filter_for_options
          advanced_filters.collect{|rec| [rec.name,rec.id]}
        end

        # Count total filtered objects.
        # _Filter_ data must be specified and find options can be passed as well.
        # 
        def advanced_filter_count filter,base_find_options={}
          base_find_options=base_find_options.delete_if{|k,v| !@@advanced_filter_allowed_keys.include?(k.to_sym)}
          set_form filter
          find_options=base_find_options.delete_if{|key,value| [:offset,:limit,:select].include?(key.to_sym)}.dup
          find_options[:conditions]=self.filter_conditions(find_options[:conditions])
          self.count_all(self.advanced_filter_merge_find_options(find_options,true))
        end
        
        #tiek izmantots to_s lai varētu iegūt objektu nos custom filter
        def advanced_filter_find filter, base_find_options={}
          base_find_options=base_find_options.delete_if{|k,v| !@@advanced_filter_allowed_keys.include?(k.to_sym)}
          set_form filter
          find_options=base_find_options.dup
          find_options[:conditions]=self.filter_conditions(find_options[:conditions])
          self.find(:all,self.advanced_filter_merge_find_options(find_options))
        end
        #saglabā filtru
        # data
        #   :name - filtra nosaukums
        #   :is_visible - Hash masīvs, key=>lauka nosaukums, :value=>true/false
        #   :conditions - Hash masīvs, key=>lauka nosaukums, :value=>same/not_same utt.
        #   :values - Hash masīvs,  key=>lauka nosaukums, :value=>Array ar vērtībām
        #   :fields - Masīvs, :value=>lauka nosaukums, parādās tikai tie lauki, mas ir atzīmēti
        #
        #   Kļūdas gadījumā izsauc kļūdu, pretējā gadījumā atgriež filtru
        def save_advanced_filter data
          filter=Filter.find_by_name(data[:name])
          unless filter
            filter=Filter.create!(:name=>data[:name],:class_name=>filter_object.to_s)
          end
          data[:is_visible].each{|field_name,visible|
            field=filter.filter_fields.find_by_name(field_name)
            unless field
              field=FilterField.create(:name=>field_name,:advanced_filter_id=>filter.id)
            end
            field.active=data[:fields] ? data[:fields].include?(field_name) : nil
            field.visible=visible
            field.sign=data[:conditions][field_name]
            field.values=data[:values][field_name]
            field.save!
          }
          filter
        end
        #var ielādēt tikai savas klases filtru
        #atgreiž filtru, kas ir masīvs ar kollonām
        def load_advanced_filter id
          filter=Filter.find(id,:conditions=>["class_name=?",filter_object.to_s]) if Filter.exists?(id)
          if !filter && filter=get_last_filter
            filter=filter.value
          end
          return load_default unless filter
          #ātrdarbībai nosaku vai ir ielādēts filtrs un ja ir vai tas nav cits filtrs
          @current=filter_from_columns(advanced_columns, filter) if current().empty? || current_filter!=filter
          @current_filter= filter
          current
        end

        def destroy_advanced_filter id
          filter=Filter.find_by_id(id)
          filter.destroy if filter
        end
        #atgriež visas kolonnas gan tabulas gan lietotāja definētās
        #jādefinē ir konstantē ADDITIONAL_FILTER
        # ja ir definēts FILTER un ADDITIONAL_FILTER
        # tad abi šie filtri tiks apvienoti, jo FILTER tiek uztverts kā tabulas definīcija
        # self vietā
        def advanced_columns
          cols=filter_object.columns || []
          if add_f=additional_filter
            cols=cols+add_f.columns
          end
          cols
        end

        protected

        #atgriežu vai nu klases objektu vai arī konstanti, kas definēta klasei ar filtru
        def additional_filter
          begin
            self::ADDITIONAL_FILTER
          rescue
            nil
          end
        end

        ## atgriež objektu, no kura tiek iegūtas pamata kolonnas,
        # parasti tas ir self, bet ir iespējams izveidot savu kollonu objektu iekš FILTER konstantes, kam
        # ir jābūt CustomFilter objektam, (skatīt custom_filter.rb)
        def filter_object
          begin
            self::FILTER
          rescue
            @object || self
          end
        end

        def get_last_filter
          UserAdvancedFilter.by_user_and_name(@user_id,self.to_s.underscore) if @user_id
        end
        #TODO iespējams vajag novākt filtru tiklīdz ienāk clear_filter
        def remove_filter
          UserAdvancedFilter.remove_filter(@user_id,self.to_s.underscore) if @user_id
        end
        def set_last_filter(filter)
          UserAdvancedFilter.set_last_filter(@user_id,self.to_s.underscore,filter) if @user_id
          filter
        end
        # lai atvieglotu strādāšanu ar saņemtajiem parametriem, un nevajadzētu tos padot kā argumentus,
        # tad saņēmējas funkcijas, izsauc šo funkciju un visi parametri pēcāk ir pieejami @form mainīgajā
        def set_form filter
          last_filter=get_last_filter
          if (filter && filter[:clear_filter]) || !last_filter
            @last_filter=self.default_filter_data_hash
            remove_filter()
          else
            @last_filter=last_filter.value if last_filter
          end
          #@@last_filter[self.to_s.underscore]={} if !self.last_filter || (filter && filter[:clear_filter])
          filter=self.collect_existing_filter_data(Filter.find_by_id(filter)) unless filter.is_a?(Hash) || filter.to_i<1
          filter=self.default_filter_data_hash unless self.last_filter
          @form=filter || self.last_filter
          @last_filter=set_last_filter(filter) if filter.is_a?(Hash) && !filter[:clear_filter]
          #@@last_filter[self.to_s.underscore]=filter
        end

        # atgriež visas kolonnas, kuru tips ir :numeric, šāds tips nav DB kolonnām,
        # tips tiek piešķirts veidojot savas kolonnas
        # sīkāk iekš custom_filter.rb
        def numeric_columns
          advanced_columns.inject([]){|options,column|
            value=column.type==:numeric ? column : nil
            options << value
          }.compact
        end

        def number_columns
          num_types=[:integer,:float]
          self.content_columns.collect{|column|
            num_types.include?(column.type.to_sym) ? column : nil
          }.compact
        end
        #lai varētu atrast kollonu ar konkrētu nosaukumu, tas ir nepieciešams
        # lai no formas datiem atrastu atbilstošu kolonnu
        def column_by_name name
          advanced_columns.each{|column|
            return column if column.name==name
          }
        end

        # atgriež filtra tabulas nosaukum
        # tabula var nebūt tikai no self, bet CustomFilter to iespējams norādīt atsevišķi
        def filter_table_name
          self.filter_object.table_name
        end

        def table
          self.to_s.split("::").last.tableize
        end
        #izveido filtru no klases kolonnām
        def load_default
          if default_filter.empty?
            default_filter = filter_from_columns advanced_columns
          end
          self.current=default_filter
          self.current_filter=nil
          default_filter
        end


        #no kollonām veido filtru, kas ir masīvs kur katrs ieraksts ir kollonnā
        #no filtra tiek izslēgtas polimorfiskās un primārās atslēgas kolonnas
        def filter_from_columns columns,saved_filter=nil
          filter=[]
          columns.each{|column|
            unless column.primary || is_polymorphic_column?(column.name)
              delete_by_name filter,column.name
              filter<<filter_row_from_column(column,saved_filter)
            end
          }
          filter
        end

        def delete_by_name arr,name
          arr.each{|element|
            arr.delete(element) if element[:name]==name
          }
        end
        # atgriež masīvu(Array), kur katrs elements ir Hash objekts, kurā
        # :object - satur ārējo objektu kolonnas filtram
        # :column - satru kolonnu, tās var būt tikai ar tipu CustomFilterColumn
        def special_filter_objects
          numeric_columns.inject([]){|arr,column|
            obj=column.table ? column.table.constantize : self
            arr<< {:object=>obj,:column=>column}
          }.compact
        end

        # darbība līdzīga kā specila_filter_foreign_objects tikai atgriež Array ar kolonnām
        def special_filter_foreign_columns
          numeric_columns.inject([]){|arr,column|
            arr<<(column.table ? column : nil)
          }.compact
        end

        # atgreiž kollonu nosaukumu, vajadzīgs, lai varētu tos iegūt arī no CustomFilter
        def advanced_column_names
          filter_object.column_names
        end
        # nosaka vai padotais kolonnas nosaukums atbilds ārējai kollonnai
        def is_foreign_column? value
          value.match(/_id\z/) && !advanced_column_names.include?("#{value.gsub(/_id\z/,"")}_type")
        end
        # nosaka vai padotais nosaukums atbilst polimorfiskās kolonnas nosaukumam
        def is_polymorphic_column? value,object=nil
          id=value.match(/_id\z/)
          type=value.match(/_type\z/)
          col_names=object ? object.column_names : advanced_column_names
          if id
            col_names.include?("#{value.gsub(/_id\z/,"")}_type")
          elsif type
            col_names.include?("#{value.gsub(/_type\z/,"")}_id")
          end
        end

        # Izmanto, lai iegūtu atsevišķu filtru tabulas filtram
        #   argumenti:
        #       column: kolonna
        #       filter: ja ir padots, tad pievieno saglabātās vērtības
        #name,type,limit,default,limit,null,precision,primary,scale,sql_type

        def filter_row_from_column column, filter=nil
          me=self.filter_object
          if me.respond_to?("titles")
            title=me.titles(column.name.to_sym)
          elsif column.respond_to?("title")
            title=column.title
          end
          main={
            :name=>column.name,
            :title=>title,
            :type=>me.get_column_type(column.type),
            :foreign=>me.is_foreign_column?(column.name),
            :foreign_type=>nil, # domāt izmantot ja otras tabulas vajadzīgais lauks nav string, tas nav default
            :foreign_data=>me.get_column_values(column.name,me.is_foreign_column?(column.name)),
            :native_type=>column.type,
            :conditions=>me.get_conditions(column.type,self.is_foreign_column?(column.name)),
            :limit=>column.limit,
            :visible=>me.last_filter[:is_visible] && (me.last_filter[:is_visible][column.name]=='true' || me.last_filter[:is_visible][column.name]==true) ? true : nil,
            :values=>me.last_filter[:values] && me.last_filter[:values][column.name] ? me.last_filter[:values][column.name] : [],
            :condition=>me.last_filter[:conditions] && me.last_filter[:conditions][column.name] ? me.last_filter[:conditions][column.name] : nil,
            :active=>me.last_filter[:fields] && me.last_filter[:fields].include?(column.name) ? true : nil
          }
          if filter
            main.merge!(me.saved_filter_field(column.name,filter))
          end
          main
        end

        #
        # Atgriež Hash masīvu ar lauka saglabātajām vērtībām
        # argumenti:
        #   column_name: lauka nosaukums
        #   filter: AdvancedFilter objekts
        #
        def saved_filter_field column_name,filter
          if filter.is_a?(Hash)
            hsh={
              :visible=>filter[:is_visible][column_name]=="true",
              :active=>filter[:fields].include?(column_name),
              :condition=>filter[:conditions][column_name],
              :values=>filter[:values][column_name]
            }
          else
            field=filter.filter_fields.find_by_name(column_name)
            hsh={
              :visible=>field.visible,
              :active=>field.active,
              :condition=>field.sign,
              :values=>field.values
            } if field
          end
          hsh || {}
        end

        def get_column_type type
          {:string=>:scalar,:integer=>:scalar,:float=>:scalar}[type] || type
        end

        # atgriež 2-dimensiju masīvu ar tipam laukam atbilstošajiem nosacījumiem
        # argumenti:
        #   type: pamattips,
        #   foreign: vai ir ārējā kolonna, pēc noklusējuma nil
        #   foreign_type: ārējās kolonnas tips, pēc noklusējuma :string
        #                 tiek izmantots, lai norādītu tipu, ja ir ārējā kollona
        #
        def get_conditions type,foreign=nil, foreign_type=:string
          type=:integer if type==:float
          if foreign && foreign_type==:string
            foreign_type=:bool
            type=foreign_type
          end
          arr={
            :bool=>["same","not_same"],
            :string=>["same","not_same","like"],
            :integer=>["same","not_same","greater","greater_or_same","smaller","smaller_or_same"],
            :datetime => ["same","greater","greater_or_same","smaller","smaller_or_same"]
          }[type.to_sym]
          (arr || []).collect{|item| [ADVANCED_FILTER_CONDITIONS[item],item]}
        end

        #ārējām kollonām tiek veidots masīvs no vērtībām no ārējās tabulas
        # teik izveidots objekts un no tā ielasītas vērtības no pirmās String tipa kollonas
        # vai arī citas norādītā tipa kollonnas, ja tāda netiek atrasta tad atgriež tukšu masīvu
        #speciāli custom filtram ir izveidots foreign column, kur iespējams norādīt konkrētu kollonu, kuras dati tiek ņemti
        def get_column_values column,foreign,foreign_type=:string
          if foreign
            foreign_name=column.respond_to?("foreign_name") ? column.foreign_name : nil #tas ir priekš customfiltercolumn
            column=column.gsub(/_id\z/,"")
            object=self.foreign_klass_for_advanced_filter(column)
            if object
              final_column=object.content_columns.detect{|f_column|
                (foreign_name && f_column.name==foreign_name) || (!foreign_name && f_column.type==foreign_type && !is_polymorphic_column?(f_column.name,object))
              }
              final_column=final_column.name if final_column
              values=object.find(:all).collect{|record|
                [record.send(final_column),record.id]
              } if final_column
              return {:values=>values,:column=>final_column} if values && !values.empty?
            end
          end
        end

        def foreign_klass_for_advanced_filter(association)
          reflection=self.filter_object.reflect_on_association(association.to_sym)
          if reflection
            reflection.klass
          else
            association="#{self.filter_object.to_s.split("::").first}/#{association}" if self.filter_object.to_s.match(/::/)
            association.to_s.camelize.constantize
          end
        end

        def default_filter_data_hash
          {:fields=>[],:conditions=>{},:values=>{},:is_visible=>{}}
        end

        def collect_existing_filter_data(filter)
          filter.filter_fields.inject(self.default_filter_data_hash){|filter_data,filter_field|
            filter_data[:fields]<<filter_field.name if filter_field.active
            filter_data[:conditions][filter_field.name]=filter_field.sign
            filter_data[:values][filter_field.name]=filter_field.values
            filter_data[:is_visible][filter_field.name]=filter_field.visible
            filter_data
          } if filter
        end

        def count_all options
          if options[:group]
            self.count("`#{self.table_name}`.id",options).size
          else
            self.count(:id, options)
          end
        end

        def advanced_filter_merge_find_options options,count=nil
          main_options=options.dup
          if add_f=self.additional_filter
            add_f.columns.each{|column|
              main_options[:group]=self.group_by_options main_options[:group],column
              if column.table
                main_options[:joins]<<self.filter_object.join_symbols_to_string([column.table.split("::").last.tableize.to_sym])[0]
              end
            }
            main_options[:joins].join(" ") if main_options[:joins].is_a?(Array)
          end
          main_options
        end

        def group_by_options group,column
          if column.group_by
            parts=column.group_by.split(",").collect{|value|
              if value.include?("?")
                value.gsub!("?","`#{self.table_name}`.`#{column.name}`")
              else
                value=value.include?(".") ? "`#{self.table_name}`.`#{value}`" : value
              end
              value
            }
            parts=parts.join(",")
            group=group.to_s.size>0 ? "#{group},#{parts}" : parts
          end
          group
        end

        def set_object_value object,name,value
          object.instance_variable_set(name,value)
        end

        # izveido sql nosacījumus no formas datiem un apvieno ar padotajiem datiem
        # tiek veidots sqls ar AND, kur katrs saņemtais lauks tiek pielīdzināts saņemtajai vērtībai(-ām)
        # ar saņemto zīmi
        def filter_conditions old_conditions
          @form[:fields].each{|field_name|
            unless self.numeric_difference?(self.column_by_name(field_name))
              old_conditions=Cms::Base.merge_conditions(self.create_conditions_from_filter_params(field_name),old_conditions)
            end
          } if @form[:fields]
          old_conditions
        end

        def create_conditions_from_filter_params(field_name)
          if @form[:values][field_name].is_a?(Array) && @form[:values][field_name].size>1 && self.column_by_name(field_name).type!=:datetime
            conditions=self.create_conditions_for_multivalue_field(field_name)
            conditions[0]="(#{conditions[0]})"
          else
            conditions=self.create_conditions_for_single_value_field(field_name)
          end
          conditions
        end

        def create_conditions_for_multivalue_field(field_name)
          sql_column="`#{self.filter_table_name}`.`#{field_name}`"
          conditions=@form[:values][field_name].inject([""]){|result,value|
            result[0]<<(@form[:conditions][field_name]=="like" ? "#{sql_column} LIKE ?" : "#{sql_column}#{SINGLESIGN[@form[:conditions][field_name]]}?")
            result[0]<<" OR "
            result<<(@form[:conditions][field_name]=="like" ? "%#{value}%" : value)
          }
          conditions[0].gsub!(/OR $/,"")
          conditions
        end

        def create_conditions_for_single_value_field(field_name)
          value=self.get_value_for_conditions(field_name)
          if value
            sql_column="`#{self.filter_table_name}`.`#{field_name}`"
            conditions=["#{sql_column}#{get_sign_for_field(field_name)}(?)"]
            conditions<<(@form[:conditions][field_name]=='like' ? "%#{value}%" : value)
          end
          conditions
        end

        def get_value_for_conditions(field_name)
          values=@form[:values][field_name]
          if self.column_by_name(field_name).type==:datetime
            eval("#{values.last=='week' ? 7 : 'values.first.to_i'}.#{values.last=='week' ? 'day' : values.last}.ago")
          else
            values.first
          end if values
        end

        def get_sign_for_field(field_name)
          if @form[:values][field_name].size>1 && self.column_by_name(field_name).type != :datetime
            MULTISIGN[@form[:conditions][field_name]]
          else
            SINGLESIGN[@form[:conditions][field_name]]
          end
        end
        # nosaka vai :numeric tipa kollonas speciālais tips ir :difference
        def numeric_difference? column
          column.type!=:numeric && column.respond_to?("numeric_type") && column.numeric_type==:difference
        end
        def last_filter
          @last_filter
        end
        def default_filter=(value)
          @default_filter=value
        end
        def default_filter
          unless @default_filter
            @default_filter=[]
          end
          @default_filter
        end

        def current
          unless @current
            @current=[]
          end
          @current
        end
        def current_filter=(value)
          @current_filter=value
        end
        def current_filter
          @current_filter
        end
        def current=(value)
          @current=value
        end

      end

      module InstanceMethods

      end

    end
    #KONTROLIERIS
    module AdvancedFilterController
      def self.included base
        base.extend( ControllerClassMethods )
        base.class_eval do
          include ControllerInstanceMethods
        end
        base.before_filter do |controller|
          controller.set_variables
        end
      end

      module ControllerClassMethods
        def apply_advanced_filter

        end
      end
      module ControllerInstanceMethods
        def set_variables
          begin
            @module=self.class.to_s.gsub(/Controller/,"")
            @module=@module.constantize
          rescue
          end
        end
      end
    end
    #BEIGAS KONTROLIER
  end

end
