require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

import 'tasks/readme.rake'

task default: %i(readme rubocop spec)

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
end

RSpec::Core::RakeTask.new(:spec)

YARD::Rake::YardocTask.new(:doc) do |t|
  t.files = ['lib/**/*.rb']
  t.stats_options = ['--list-undoc']
end
