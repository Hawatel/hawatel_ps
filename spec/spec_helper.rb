require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'hawatel_ps'
require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
  end

  config.before(:suite) do
    FactoryGirl.definition_file_paths = %W(spec/linux/factories spec/windows/factories)
    FactoryGirl.find_definitions
  end
end