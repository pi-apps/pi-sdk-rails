require "bundler/setup"

#APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

require "bundler/gem_tasks"
# Load RSpec tasks
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

# Load Appraisal tasks (this makes 'appraisal rake' aware of your tasks)
require 'appraisal/rake_task'

# Optional: Define a default task
task default: :spec
