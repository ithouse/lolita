module Lolita
  module Configuration
    class Page
 
      # page options is used to define specific options for pagination like :joins or :conditions
      lolita_accessor :page_options
      attr_writer :per_page
      
      def initialize(dbi)
        @dbi=dbi
        @sort_columns=[]
      end
      
      # Records per page (also block setter)
      def per_page(value=nil)
        @per_page=value if value
        @per_page
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
      def sort_columns
        @sort_columns
      end

      # Paginate
      # Options:
      # * <tt>:per_page</tt> - Records per page, if not given use list default per page.
      # * <tt>:page</tt> - Comment to get
      # * <tt>page</tt> - Comment to get
      # ====Example
      #     list.paginate(1)
      #     list.paginate
      #     lsit.paginate(:per_page=>2,:page=>1)
      def paginate *args
        options=args ? args.extract_options! : {}
        set_values_from_options(options)
        options[:page]||=((args && args.first) || 1)
        options[:per_page]||=@per_page || 10
        @page=@dbi.paginate((@page_options||{}).merge(options))
      end

      # Return last paginated page
      # ====Example
      #     list.paginate(2)
      #     # call page to avoid another call to db
      #     list.page
      def last
        @page
      end
      
      private
      
      def set_values_from_options(options)
        
      end
    end
  end
end