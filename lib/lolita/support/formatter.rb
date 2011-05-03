module Lolita
  module Support
    # Containes different kind of formaters.
    # Change output format of different input types.
    # To define, pass block, or String.
    # ====Exmaple
    #     Lolita::Support::Formatter.new do |value|
    #       value.to_i**2
    #     end
    #     # or as String
    #     Lolita::Support::Formatter.new("%U")
    # To format any value with defined formater call #with
    # ====Example
    #     # Previous examples may be called like this
    #     formatter.with(1)
    #     formatter.with(Date.today)
    class Formatter

      def initialize(format=nil,&block)
        @format=format
        @block=block if block_given?
      end

      def format
        @format
      end

      def block
        @block
      end

      def with(value,*optional_values)
        if @block
          @block.call(value,*optional_values)
        elsif @format
          use_format_for(value,*optional_values)
        else
          use_default_format(value,*optional_values)
        end
      end

      private

      def use_default_format(value,*optional_values)
        value
      end

      def use_format_for(value, *optional_values)
        if value.respond_to?(:format)
          call_block(value,*optional_values)
        else
          value.to_s.unpack(@format)
        end
      end

      def call_block(value,*optional_values)
        value.send(:format,value,*optional_values)
      end

    end
    
  end
end