RSpec.configure do |config|
  if LOLITA_ORM == :active_record
    config.use_transactional_fixtures = false
  end
  DatabaseCleaner.strategy = :truncation

  config.around(:each) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end
end
