module Lolita
  module DBI
    class RecordSet < Lolita::DBI::AbstractInterface
      include Enumerable

      attr_accessor :page,:per_page
      def initialize(dbi,options={})
        super(dbi)
        @options=options
        @options[:page]=@options[:page].to_i<1 ? 1 : @options[:page].to_i
        @options[:per_page]=@options[:per_page].to_i<1 ? 1 : @options[:per_page].to_i
        @records=paginate()
      end

      def each
        @records.each{|r| yield r}
      end

    end
  end
end
