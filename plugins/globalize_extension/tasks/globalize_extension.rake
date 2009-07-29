namespace :globalize do
  namespace :extension do
    desc 'Run Globalize tests'
    Rake::TestTask.new do |t| # from the Globalize plugins
      t.test_files = FileList["#{File.dirname( __FILE__ )}/../test/*_test.rb"]
      t.verbose = true
    end
  end
end
