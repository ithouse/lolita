module Lolita
  module DBI
    class RecordSet
      include Enumerable
      include Lolita::DBI::AbstractInterface

      attr_accessor :page,:per_page

      # Create new RecordSet
      # * <tt>dbi</tt> - Lolita::DBI::Base object
      # * <tt>options</tt> - :page, :per_page and other find supported options.
      def initialize(dbi,options={})
        connect_adapter(dbi)
        @options=options
        @options[:page]=@options[:page].to_i<1 ? 1 : @options[:page].to_i
        @options[:per_page]=@options[:per_page].to_i<1 ? 1 : @options[:per_page].to_i
        @is_loaded=false
        @records=[]
      end

      # Is records realy loaded.
      def is_loaded?
        @is_loaded
      end

      # Load records for real.
      def load
        @records=self.paginate unless is_loaded?
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
