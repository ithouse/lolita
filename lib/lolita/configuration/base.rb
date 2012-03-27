module Lolita
  module Configuration
    # This is superclass of other configuration classes, that is used to configure different parts of resource. 
    class Base
      include Lolita::Builder
      attr_reader :dbi

      private

      def set_and_validate_dbi(dbp)
        @dbi = dbp
        raise Lolita::UnknownDBIError.new("No DBP specified for #{self.class.to_s.split("::").last}") unless @dbi
      end

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

