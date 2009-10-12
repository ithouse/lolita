module Lolita
  class Paginator
    include Enumerable
    #include Comparable
    attr_accessor :per_page
    attr_accessor :total_records
    attr_accessor :total_pages
    attr_accessor :sort_direction
    attr_accessor :sort_column
    attr_accessor :page
    attr_reader   :parent
    attr_reader   :start_row
    attr_reader   :do_ferret
    attr_accessor :ferret_filter
    attr_accessor :advanced_filter
    attr_accessor :simple_filter
    attr_accessor :padding
    attr_accessor :find_options
    @@default_keys=[:conditions,:include,:select,:limit,:offset,:group,:order,:joins,:readonly,:from,:lock]

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

    def method_missing(symbol, *args, &block)
      @results.send(symbol, *args, &block)
    end

    def inspect
      @results
    end

#    def <=>(other)
#      @results.size<=>other.size
#    end
#
    def each
      @results.each{|item|
        yield item
      }
    end

    def create options={}
      get_values_from_options options
      self.calculate_arguments
      self.find_records
    end

    def count
      #self.calculate_arguments(options[:parent],options,params) unless is_args_calculated?
      count=if do_ferret
        self.parent.total_hits(self.ferret_filter)
      elsif self.parent.has_advanced_filter?
        self.parent.advanced_filter_count(self.advanced_filter,self.find_options.delete_if{|key,value| [:readonly,:lock].include?(key)})
      else
        self.parent.count(:all,:joins=>self.find_options[:joins], :conditions=>self.find_options[:conditions],:group=>self.find_options[:group])
      end
      self.total_records=count.is_a?(Array) ? count.size : count
    end

    def find_records
      #self.calculate_arguments(self.parent,options,params) unless is_args_calculated?
      # order="#{self.sort_column} #{self.sort_direction}"
      #find_options={:joins=>options[:include],:conditions=>options[:conditions],:group=>options[:group],:order=>order,:offset=>self.start_row,:limit=>self.per_page}
      if do_ferret
        @results=self.parent.find_with_ferret(ferret_filter, {:offset=>self.start_row, :limit=>self.per_page})
      elsif self.parent.has_advanced_filter?
        @results=self.parent.advanced_filter_find(self.advanced_filter,find_options)
      else
        @results=self.parent.find(:all,find_options)
      end
    end

    def current_page
      @page
    end
    alias :current :current_page

    def total_pages
      @total_pages
    end
    alias :page_count :total_pages

    def next_page
      self.start_row+self.per_page>self.total_records.to_i ? 1 : self.page+1
    end

    def previous_page
      self.start_row-self.per_page<0 ? 1 : self.page-1
    end

    def last_page
      self.page+self.padding>self.total_pages ? self.total_pages : self.page+self.padding
    end

    def first_page
      self.page-self.padding<1 ? 1 : self.page-self.padding
    end

    def simple_sort_column
      self.sort_column.split(",").collect{|col| col.split(".").last.gsub("`","")}.join(",") if self.sort_column
    end

    def set_results(results,total_rec=false)
      @results=results
      calculate_arguments(total_rec)
    end

    def is_args_calculated?
      @args_calculated
    end
    protected

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

    def get_value_from_options hash={}
      hash.each{|key,value|
        self.send("#{key}=",value) if self.respond_to?("#{key}=")
      }
    end

    def calculate_arguments(total_rec=false)
      @args_calculated=true
      self.per_page||=30
      unless total_rec #TODO atdalīt no aprēķiniem
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

      #options.keys-@@default_keys.each{|key| options.delete(key)} TODO pārtaisīt lai ir tikai vajadzīgaš vērtības un nav lieki jāpadod options
    end

    def set_find_options
      self.find_options[:offset]=@start_row
      self.find_options[:limit]=self.per_page
      if self.sort_column
        self.find_options[:order]="#{self.sort_column} #{self.sort_direction}"
      end
    end
    #    def default_find_options
    #      {:joins=>[],:conditions=>[],:group=>nil,:order=>nil,:offset=>nil,:limit=>nil}
    #    end

  end
end