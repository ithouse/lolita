module Lolita
  module Generators
    class UninstallGenerator < Rails::Generators::Base
      ROUTE_NAME = "lolita_for"
      INCLUDE_MODULE = "Lolita::Configuration"
      MODEL_METHOD = "lolita"

      desc "Uninstall Lolita and remove all dependencies"

      def ask_to_continue
        #ask("Do you want to remove initializer, clear routes and remove Lolita from models? [y]es/[n]o")
      end
      # Remove lolita initializer file
      def remove_initializer
        if File.exist?(Rails.root + "config/initializers/lolita.rb")
          remove_file "config/initializers/lolita.rb"
        end
      end

      # Remove all not-commented lines that begins with lolita_for
      def clear_routes
        gsub_file File.join(Rails.root,"config","routes.rb"), /^\s*#{ROUTE_NAME}.*/ do |match|
          match.clear
          match
        end
      end

      # Remove configuration include line and lolita block or single lolita method call.
      # Block will be removed correctly if it starts with _do_ and ends with _end_. 
      def clear_models
        Dir[File.join(Rails.root,"app","models","*.rb")].each do |file_name|
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