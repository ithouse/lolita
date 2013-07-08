module Lolita
  module Generators
    class UninstallGenerator < Rails::Generators::Base
      ROUTE_NAME = "lolita_for"
      INCLUDE_MODULE = "Lolita::Configuration"
      MODEL_METHOD = "lolita"

      desc "Uninstall Lolita and remove all dependencies"

      # Remove lolita initializer file
      def remove_initializer
        remove_file "config/initializers/lolita.rb"
      end

      # Remove all not-commented lines that begins with lolita_for
      def clear_routes
        gsub_file Rails.root.join("config","routes.rb"), /^\s*#{ROUTE_NAME}.*/ do |match|
          match.clear
          match
        end
      end

      # Remove configuration include line and lolita block or single lolita method call.
      # Block will be removed correctly if it starts with _do_ and ends with _end_. 
      def clear_models
        Dir[Rails.root.join("app","models","*.rb")].each do |file_name|
          matched = false
          gsub_file file_name, /^\s*include\s+#{INCLUDE_MODULE}.*/ do |match|
            matched = true
            match.clear
            match
          end
          if matched
            new_lines = []
            File.open(file_name,"r") do |file|
              do_count = nil
              file.each_line do |line|
                if do_count.nil?
                  if line.match(/^(\s*)lolita\s+(do)?/)
                    if $2 == "do"
                      do_count = 1
                    else
                      do_count = 0
                    end
                  else
                    new_lines << line
                  end
                elsif do_count > 0
                  if line.match(/(^|\s+)do(\s+|$)/)
                    do_count +=1
                  elsif line.match(/(^|\s+)end(\s+|$)/)
                    do_count -=1
                  end
                else
                  new_lines << line
                end
              end
            end
            File.open(file_name,"w") do |file|
              new_lines.each do |line|
                file.puts(line)
              end
            end

          end
        end
      end

    end
  end
end