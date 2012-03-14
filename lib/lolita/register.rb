module Lolita
  
  class Register
    def initialize
      @store = {}
    end

    def set key, value, options=nil
      !!(@store[key] = [value,options].compact)
    end

    def get key
      item = @store[key] and item.first
    end

    def get_with_options key
      @store[key]
    end

    def filter *args
      options = args.extract_options!
      values = if args.first
        [get_with_options(args.first)]
      else
        @store.values
      end
      filter_values(values,options)
    end

    private

    def filter_values values, pattern
      unless (pattern && pattern.any?)
        values
      else
        values.inject([]) do |result,value|
          if value[1]
            if (pattern.to_a - value[1].to_a).empty?
              result.push value
            end
          end
          result
        end
      end
    end
  end

end