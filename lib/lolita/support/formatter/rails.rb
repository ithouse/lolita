module Lolita
  module Support
    class Formatter

      # Formater for work with rails, it localize Date and Time.
      # Also
      class Rails < Lolita::Support::Formatter


        private

        def use_format_for(value,*optional_values)
          if @format && (value.is_a?(Time) || value.is_a?(Date))
            localize_time_with_format(value,*optional_values)
          else
            use_default_format(value,*optional_values)
          end
        end

        def localize_time_with_format(value,*optional_values)
          if defined?(::I18n)
            ::I18n.localize(value, :format => @format)
          else
            use_default_format(value,*optional_values)
          end
        end

        def use_default_format(value,*optional_values)
          if value
            if value.is_a?(String)
              value
            elsif value.is_a?(Numeric)
              value
            elsif value.is_a?(Date)
              if defined?(::I18n)
                ::I18n.localize(value, :format => :long)
              else
                value.strftime("%Y/%m%/%d")
              end
            elsif value.is_a?(Time)
              if defined?(::I18n)
                ::I18n.localize(value, :format => :long)
              else
                value.strftime("%Y/%m/%d %H:%M:%S")
              end
            else
              value.to_s
            end
          else
            ""
          end
        end
      end

    end
  end
end