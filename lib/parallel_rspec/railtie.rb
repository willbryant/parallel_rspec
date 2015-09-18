require 'rails'

module ParallelRSpec
  class Railtie < Rails::Railtie
    railtie_name :parallel_rspec

    rake_tasks do
      load "parallel_rspec/tasks.rake"
    end
  end
end
