module Lolita
  module Adapter
    module CommonHelper

      def switch_record_mode(record, mode = nil)
        set_access_mode_for(record)
        if mode
          record.send(:"#{mode}_mode!") 
        elsif !record.have_mode?
          if record.new_record?
            record.create_mode!
          else 
            record.update_mode!
          end
        end
        record
      end
      
      def set_access_mode_for(record)
        unless record.respond_to?(:read_mode!)
          class << record

            def set_mode(new_mode)
              @mode_set = true
              @mode = new_mode
            end

            def have_mode?
              @mode_set
            end

            def read_mode!
              set_mode :read
            end

            def create_mode!
              set_mode :create
            end

            def update_mode!
              set_mode :update
            end

            def mode
              set_mode(:read) unless @mode
              @mode
            end

            def in_read_mode?
              mode == :read
            end

            def in_create_mode?
              mode == :create
            end

            def in_update_mode?
              mode == :update
            end
          end
        end
        record
      end

    end
  end
end