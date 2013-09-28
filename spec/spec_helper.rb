require 'palimpsest'

require 'coveralls'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start

RSpec.configure do |c|
  c.expect_with(:rspec) { |e| e.syntax = :expect }

  c.after :suite do
    Dir.glob("#{Palimpsest::Environment.new.options[:tmp_dir]}/#{Palimpsest::Environment.new.options[:dir_prefix]}*").each do |dir|
      FileUtils.remove_entry_secure dir
    end
  end
end
