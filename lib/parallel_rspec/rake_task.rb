require 'rspec/core/rake_task'

module ParallelRSpec
  class RakeTask < RSpec::Core::RakeTask
    def initialize(*args, &task_block)
      super
      self.rspec_path = File.expand_path('../../../exe/prspec', __FILE__)
    end
  end
end
