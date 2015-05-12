require 'simplecov'

SimpleCov.start

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
else
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
end

require 'palimpsest'

RSpec.configure do |c|
  c.expect_with(:rspec) { |e| e.syntax = :expect }
  c.before(:each) do
    allow(FileUtils).to receive(:remove_entry_secure).with(anything)
  end

  c.after :suite do
    Dir.glob("#{Palimpsest::Environment.new.options[:tmp_dir]}/" \
             "#{Palimpsest::Environment.new.options[:dir_prefix]}*").each do |dir|
      FileUtils.remove_entry_secure dir
    end
  end
end
