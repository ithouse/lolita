module Lolita
  module Filters
    class CustomFilter
      attr_reader :columns
      def initialize options={}
        @class_name=options[:class_name] || "Lolita::Filters::CustomFilter"
        @columns=[]
        @column_names=[]
        options[:columns].each{|configuration|
          column=CustomFilterColumn.new(configuration)
          @columns <<  column
        }
      end
      
      def column_names
        @column_names ||= columns.map { |column| column.name }
      end
      
      def to_s
        @class_name
      end
    end
    #name,type,limit,default,limit,null,precision,primary,scale,sql_type
    class CustomFilterColumn 
      attr_reader :name
      attr_reader :title
      attr_reader :type
      attr_reader :limit
      attr_reader :default
      attr_reader :null
      attr_reader :primary
      attr_reader :mask
      attr_reader :sql
      attr_reader :numeric_type
      attr_reader :foreign_name
      attr_reader :group_by
      attr_reader :period
      attr_reader :table # lai varētu norādit piemēram Meters.find(:all).foreign_table
      attr_reader :conditions
      attr_reader :sign
      attr_reader :aggregate_function
      attr_reader :hidden
      
      def initialize options={}
        @name=options[:name]
        @title=options[:title] || options[:name].to_s.humanize
        @type=options[:type]
        @limit=options[:limit] || 1
        @default=options[:default]
        @null=options[:null]
        @primary=options[:primary]
        @mask=options[:mask] # TODO jāpadomā
        @sql=options[:sql]
        @numeric_type=options[:numeric_type]
        @foreign_name=options[:foreign_name]
        @group_by=options[:group_by]
        @period=options[:perion] || "day"
        @table=options[:table]
        @conditions=options[:conditions] 
        @sign=options[:sign] || "="
        @aggregate_function=options[:aggregate_function]
      end
      
      def to_s
        "Lolita::Filters::CustomFilterColumn"
      end
    end
  end
end
