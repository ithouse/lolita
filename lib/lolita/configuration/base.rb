module Lolita
  module Configuration
    # This is superclass of other configuration classes, that is used to configure different parts of resource. 
    class Base
      include Lolita::Builder
      attr_reader :dbi
      alias :dbp :dbi

      def initialize(dbp, *args)
        set_and_validate_dbp dbp
        set_attributes *args
      end

      private

      def set_and_validate_dbp(dbp)
        @dbp = dbp
        @dbi = dbp
        raise Lolita::UnknownDBPError.new("No DBP specified for #{self.class.to_s.split("::").last}") unless @dbp
      end

      alias :set_and_validate_dbi :set_and_validate_dbp

      # Used to set attributes if block not given.
      def set_attributes(*args)
        options = args && args.extract_options! || {}
        options.each do |attr_name,value|
          self.send("#{attr_name}=".to_sym,value)
        end
      end

    end

  end
end

