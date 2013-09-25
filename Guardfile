guard :rspec, cli: '--color --format Fuubar' do
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb') { 'spec' }
end

guard :yard do
  watch(%r{^lib/(.+)\.rb$})
end
