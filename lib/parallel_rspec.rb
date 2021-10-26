require "parallel_rspec/version"
require "parallel_rspec/config"
require "parallel_rspec/channel"
require "parallel_rspec/workers"
require "parallel_rspec/example"
require "parallel_rspec/server"
require "parallel_rspec/client"
require "parallel_rspec/rake_task"
require "parallel_rspec/runner"
require "parallel_rspec/railtie"

module ParallelRSpec
  def self.configure
    yield Config
  end

  def self.running?
    Runner.running?
  end
end
