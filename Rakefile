require 'rake'
require 'rspec/core/rake_task'

namespace :test do
  #
  # RSpec unit tests are those tests not marked with the
  # integration tag.
  #
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = ['spec/**/*_spec.rb']
  end

  #
  # RSpec integration tests are marked with the integration tag
  #
  #     it "something", :integration => true do
  #     end
  #
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.rspec_opts = "--tag integration"
    t.pattern = ['spec/**/*_spec.rb']
  end
end

task :default => 'test:unit'

