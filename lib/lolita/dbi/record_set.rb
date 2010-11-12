# Used to get page of records. Use Lolita::DBI::Base to collect records.
# If not asked for records then do not load them.
module Lolita
  module DBI
    class RecordSet
      DEFAULT_PER_PAGE=30
      include Enumerable

      attr_accessor :page,:per_page
      attr_reader :records

      # Create new RecordSet
      # * <tt>dbi</tt> - Lolita::DBI::Base object
      # * <tt>options</tt> - :page, :per_page and other find supported options.
      def initialize(dbi,options={})
        @dbi=dbi
        @options=options
        @options[:page]=@options[:page].to_i<1 ? 1 : @options[:page].to_i
        @options[:per_page]=@options[:per_page].to_i<1 ? DEFAULT_PER_PAGE : @options[:per_page].to_i
        @is_loaded=false
        @records=[]
      end

      # Is records realy loaded.
      def is_loaded?
        @is_loaded
      end

      # Load records for real.
      def load
        @records=@dbi.paginate(@options) unless is_loaded?
        @is_loaded=true
      end

      def each
        load
        @records.each{|rec| yield rec}
      end

      # Redirect any unsupported method to @records array, like #Array.size.
      def method_missing(method,*args,&block)
        load
        @records.__send__(method,*args,&block)
      end
    end
  end
end
