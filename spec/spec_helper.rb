require 'palimpsest'

require 'simplecov'

SimpleCov.start

RSpec.configure do |c|
  c.expect_with(:rspec) { |e| e.syntax = :expect }
end
