module Lolita
  # Paginator is used to paginate any of ActiveRecord::Base class records.
  # But main advantage is usage with Lolita filters. Paginator support simple text filtering
  # Lolita::Filter::AdvancedFilter and with Ferret.
  # Paginator instace include #Enumerable and that allow to iterate through it.
  # ====Example
  #   paginator=Lolita::Paginator.new(Cms::Blog,{
  #     :per_page=>10,
  #     :page=>1,
  #     :conditions=>["name = ?", "Jim"],
  #     :sort_column=>"name",
  #     :sort_direction=>"asc"
  #   })
  #   paginator.find_records().map{|r| r.id} #=> [1,2,3]
  #
  class Paginator
    include Enumerable
    # Record count in page
    attr_accessor :per_page
    # Total records found with given conditions
    attr_accessor :total_records
    # Total pages
    attr_accessor :total_pages
    # MySql sort direction _asc_ or _desc_
    attr_accessor :sort_direction
    # Sort column or columns 
    attr_accessor :sort_column
    # Current page number
    attr_accessor :page
    # Parent class
    attr_reader   :parent
    # Start row used in MySQL limit
    attr_reader   :start_row
    # Store ferret filter data
    attr_reader   :do_ferret
    # Ferret filter find _options_
    attr_accessor :ferret_filter
    # Advanced filter find _options_
    attr_accessor :advanced_filter
    # Simple filter find _options_
    attr_accessor :simple_filter
    # Determine how pages are displayed before and after current page.
    attr_accessor :padding
    # Simple find options, #ActiveRecord::Base style.
    attr_accessor :find_options
    @@default_keys=[:conditions,:include,:select,:limit,:offset,:group,:order,:joins,:readonly,:from,:lock]

    # Constructor that receive <i>parent_class</i> and configuration
    # ====Example
    #     Lolita::Paginator.new(Cms::Blog,{:page=>1,:per_page=>20})
    # Following configuration options are accptable:
    # * <tt>:per_page</tt> - records in page
    # * <tt>:page</tt> - current page number, 1 for first page
    # * <tt>:padding</tt> - number of pages that be displayed before and after current page when displaying paginator bar.
    # * <tt>:simple_filter</tt> - all content fields would be filtered using this value.
    # * <tt>:advanced_filter</tt> - advanced filter. See #Lolita::Filter::AdvancedFilter
    # * <tt>:sort_column</tt> - sort column(-s)
    # * <tt>:sort_direction</tt> - sort direction
    # * Any of ActiveRecord::Base#find options. When using AdvancedFilter :read_only and :lock not be used, but when
    #   Ferret filter, than none of these options.
    # Other options could be passed that are same with writtable attributes, but that might raise an error or
    # make other strange side effects.
    #
    def initialize parent_class,config={}
      @find_options={}
      @results=[]
      @parent=parent_class
      @@default_keys.each{|d_key| @find_options[d_key]=config[d_key]}
      get_value_from_options config
      @do_ferret = config[:ferret_filter] && @parent.respond_to?(:ferret_enabled?) && @parent.ferret_enabled?
      @per_page||= 30
      @padding||=3
      self.create_simple_filter_conditions(config[:simple_filter]) if config[:simple_filter] && config[:simple_filter].to_s.size>0
      self.calculate_arguments
    end

    # When non-existing method on #Lolita::Paginator instance is called, then
    # try to call that method on find _results_.
    def method_missing(symbol, *args, &block)
      @results.send(symbol, *args, &block)
    end

    # Return find _results_
    def inspect
      @results
    end

    def each # :nodoc: 
      @results.each{|item|
        yield item
      }
    end

    # Find records from <em>parent_class</em>.
    # New configuration can be set by supplying _options_.
    # ====Example
    #    paginator=Lolita::Paginator.new(Cms::Blog,:per_page=>2)
    #    page=paginator.create(:per_page=>10)
    #    page.size #=> 10
    def create options={}
      get_values_from_options options
      self.calculate_arguments
      self.find_records
    end

    # Set <em>total_records</em>.
    def count
      count=if do_ferret
        self.parent.total_hits(self.ferret_filter)
      elsif self.parent.has_advanced_filter?
        self.parent.advanced_filter_count(self.advanced_filter,self.find_options.delete_if{|key,value| [:readonly,:lock].include?(key)})
      else
        self.parent.count(:all,:include=>self.find_options[:include],:joins=>self.find_options[:joins], :conditions=>self.find_options[:conditions],:group=>self.find_options[:group])
      end
      self.total_records=count.is_a?(Array) ? count.size : count
    end

    # Find current page records and set _results_.
    def find_records
      if do_ferret
        @results=self.parent.find_with_ferret(ferret_filter, {:offset=>self.start_row, :limit=>self.per_page})
      elsif self.parent.has_advanced_filter?
        @results=self.parent.advanced_filter_find(self.advanced_filter,find_options)
      else
        @results=self.parent.find(:all,find_options)
      end
    end

    # Return current page.
    # ====Example
    #     paginator.current_page #=> 2
    def current_page
      @page
    end
    alias :current :current_page

    # Return total pages.
    def total_pages
      @total_pages
    end
    alias :page_count :total_pages

    # Calculate next page.
    # ====Example
    #     paginator.per_page #=> 10
    #     paginator.page #=> 5
    #     paginator.total_pages #=>8
    #     paginator.next_page #=> 6
    #     # When greater or same with total pages
    #     paginator.total_pages #=> 5
    #     paginator.next_page #=> 5
    def next_page
      self.start_row+self.per_page>self.total_records.to_i ? self.total_pages : self.page+1
    end

    # Return previous page, when less than 1, then return 1.
    def previous_page
      self.start_row-self.per_page<0 ? 1 : self.page-1
    end

    # Last page in paginator to display.
    # Always try to return page number of 2 times padding + current page
    # ====Example
    #  paginator.padding #=> 3
    #  paginator.current_page #=> 2
    #  paginator.total_pages #=> 50
    #  paginator.page.last_page #=> 7
    def last_page
      if self.page+self.padding>self.total_pages
        self.total_pages
      elsif self.page+self.padding<self.padding*2+1
        self.padding*2+1>self.total_pages ? self.total_pages : self.padding*2+1
      else
        self.page+self.padding
      end
    end

    # First page in paginator to display.
    # ====Example
    #  paginator.padding #=>3
    #  paginator.current_page #=> 9
    #  paginator.first_page #=> 6
    def first_page
      self.page-self.padding<1 ? 1 : self.page-self.padding
    end

    # Return first record index, starts with 1, if no records than 0
    def first_index
      self.total_records==0 ? 0 : self.start_row+1
    end
    # Return last record index, if less than per page than return total records, else
    # current record index + records per page
    def last_index
      self.start_row+self.per_page>self.total_records ? self.total_records : self.start_row+self.per_page
    end

    # Return sort column.
    # ====Example
    #     paginator.sort_column #=> "id"
    #     paginator.simple_sort_column #=> `id`
    #     paginator.sort_column #=> "cms_blogs.id, cms_blogs.user_id"
    #     paginator.simple_sort_column #=> `id`, `user_id`
    def simple_sort_column
      self.sort_column.split(",").collect{|col| col.split(".").last.gsub("`","")}.join(",") if self.sort_column
    end

    # When records finding are too complicated to #Lolita::Paginator can handle it,
    # than anyway paginator can be used by seting _results_ manualy.
    # ====Example
    #     paginator.set_results(Cms::Blog.my_complicated_find,Cms::Blog.my_complicated_count)
    #     paginators.total_records == Cms::Blog.my_complicated_count #=> true
    def set_results(results,total_rec=false)
      @results=results
      calculate_arguments(total_rec)
    end

    def is_args_calculated? # :nodoc: 
      @args_calculated
    end
    protected

    # Join <em>find_options[:conditions]</em> with conditions created from <em>:simple_filter</em>
    # ====Example
    #   paginator.find_options #=> {:conditions=>["id IN (1,2,3)"]}
    #   Cms::Blog.column_names #=> [:id,:text,:user_id, :nr]
    #   create_simple_filter_conditions("my name is Earl")
    #   paginator.find_options #=> {:conditions=>[
    #     "(id IN (1,2,3)) AND (`cms_blogs`.`text` LIKE ? AND `cms_blogs`.`nr`=?)",
    #     "my name is Earl%","my name is Earl"
    #   ]}
    def create_simple_filter_conditions(filter)
      new_cond=@parent.content_columns.inject([[]]){|cond,column|
        if [:string,:integer,:float].include?(column.type)
          unless column.type==:string
            cond[0]<<"`#{@parent.table_name}`.`#{column.name}`=?"
            cond<<filter
          else
            cond[0]<<"`#{@parent.table_name}`.`#{column.name}` LIKE ?"
            cond<<"#{filter}%"
          end
        else
          cond
        end
      }
      new_cond[0]=new_cond[0].join(" OR ")
      self.find_options[:conditions]=Cms::Base.cms_merge_conditions(new_cond,self.find_options[:conditions])
      self.simple_filter=filter
    end

    def get_value_from_options hash={} # :nodoc: 
      hash.each{|key,value|
        self.send("#{key}=",value) if self.respond_to?("#{key}=")
      }
    end

    # Calculate arguments. Is called when _paginator_ configuration changes.
    def calculate_arguments(total_rec=false)
      @args_calculated=true
      self.per_page||=30
      unless total_rec 
        self.total_records=self.count
      else
        self.total_records=total_rec
      end
      self.page=self.page.to_i<1 ? 1 : self.page.to_i
      self.total_pages=(self.total_records.to_f/self.per_page.to_f).ceil
      self.total_pages=self.total_pages.to_i<1 ? 1 : self.total_pages
      self.page=self.total_pages if self.page>self.total_pages

      self.sort_direction||= "asc"
      @start_row=(self.page-1)*self.per_page
      set_find_options
    end

    # Set <em>find_options</em>.
    def set_find_options
      self.find_options[:offset]=@start_row
      self.find_options[:limit]=self.per_page
      if self.sort_column
        self.find_options[:order]="#{self.sort_column} #{self.sort_direction}"
      end
    end

  end
end