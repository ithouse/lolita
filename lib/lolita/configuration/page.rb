module Lolita
  module Configuration
    class Page

      # page options is used to define specific options for pagination like :joins or :conditions
      lolita_accessor :page_options
      attr_writer :per_page
      def initialize(dbi, list)
        @dbi=dbi
        @list = list
        @sort_columns=[]
      end

      # Records per page (also block setter)
      def per_page(value=nil)
        if value
          @per_page=value
          self
        else
          @per_page
        end
      end

      # Define new sort column with ascending sort direction
      def asc(column)
        @sort_columns<<[column.to_sym,:asc]
        self
      end

      # Define new sort columns with descending sort direction
      def desc(column)
        @sort_columns<<[column.to_sym,:desc]
        self
      end

      # Return all sort columns.
      # Each column is an Array where first element is column name and second is direction
      # ====Example
      #     page=Lolita::Configuration::Page.new(@dbi)
      #     page.asc(:created_at)
      #     page.sort_columns #=> [[:created_at,:asc]]
      def sort_columns
        @sort_columns
      end

      # Paginate
      # Options:
      # * <tt>:per_page</tt> - record count per page, default uses list.per_page
      # * <tt>:page</tt> - what page to show
      # * <tt>:sort_columns</tt> - sort columns for page. See #sort_columns
      # * <tt>:asc</tt> - column to sort in ascending direction
      #     list.paginate(1,:asc=>:created_at)
      # * <tt>:desc</tt> - column to sort in descending direction
      #
      # ====Example
      #     list.paginate(1)
      #     list.paginate
      #     list.paginate(:per_page=>2,:page=>1)
      def paginate *args
        options=args ? args.extract_options! : {}
        hold=options.delete(:hold)
        @params=options.delete(:params)
        set_values_from_options(options)
        options[:page]||=((args && args.first) || 1)
        options[:per_page]||=@per_page || 10
        @last_options=options
        @last_options[:sort]=self.sort_columns unless self.sort_columns.empty?
        unless hold
          get_page()
        end
      end

      def get_page()
        @page=@dbi.filter(filter_conditions).paginate((@page_options||{}).merge(@last_options))
      end
      
      # Return last paginated page
      # ====Example
      #     list.paginate(2)
      #     # call page to avoid another call to db
      #     list.page
      def last_page
        @page
      end

      private

      # returns filter conditions as Hash for get_page()
      def filter_conditions
        if @params
          conditions = {}
          @params.each_pair do |k,v|
            if k.to_s =~ /^f_([a-z0-9_\-]+)$/ && !v.to_s.strip.blank?
              conditions[$1.to_sym] = v
            end
          end
          conditions
        else
          {}
        end
      end

      def allowed_options
        [:sort_columns,:asc,:desc]
      end

      def set_values_from_options(options)
        allowed_options.each{|meth|
          if options.has_key?(meth)
            self.send(meth,options.delete(meth))
          end
        }
        parse_params
      end

      def parse_params
        if @params
          if @params.has_key?(:sc)
            self.send((@params[:sd] || :asc).to_sym,@params[:sc])
          end
        end
      end

    end
  end
end