require 'rspec/core'

module RSpec
  module Core
    class ExampleGroup
      def self.any_context_hooks?
        # unfortunately the public HookCollection API doesn't make this information available, so we have to grab it from internals
        descendants.any? do |group| # despite the name, descendents includes self
          group.hooks.send(:matching_hooks_for, :before, :context, group).present? ||
            group.hooks.send(:matching_hooks_for, :after, :context, group).present?
        end
      end
    end
  end
end

module ParallelRSpec
  class Runner < RSpec::Core::Runner
    # Runs the suite of specs and exits the process with an appropriate exit
    # code.
    def self.invoke
      status = run(ARGV, $stderr, $stdout).to_i
      exit(status) if status != 0
    end

    # Run a suite of RSpec examples. Does not exit.
    #
    # This is used internally by RSpec to run a suite, but is available
    # for use by any other automation tool.
    #
    # If you want to run this multiple times in the same process, and you
    # want files like `spec_helper.rb` to be reloaded, be sure to load `load`
    # instead of `require`.
    #
    # @param args [Array] command-line-supported arguments
    # @param err [IO] error stream
    # @param out [IO] output stream
    # @return [Fixnum] exit status code. 0 if all specs passed,
    #   or the configured failure exit code (1 by default) if specs
    #   failed.
    def self.run(args, err=$stderr, out=$stdout)
      RSpec::Core::Runner.trap_interrupt
      options = RSpec::Core::ConfigurationOptions.new(args)
      new(options).run(err, out)
    end

    # Runs the provided example groups.
    #
    # @param example_groups [Array<RSpec::Core::ExampleGroup>] groups to run
    # @return [Fixnum] exit status code. 0 if all specs passed,
    #   or the configured failure exit code (1 by default) if specs
    #   failed.
    def run_specs(example_groups)
      @configuration.reporter.report(@world.example_count(example_groups)) do |reporter|
        @configuration.with_suite_hooks do
          with_context_hooks, without_context_hooks = example_groups.partition(&:any_context_hooks?)
          success = run_in_parallel(without_context_hooks, reporter)
          success &&= with_context_hooks.map { |g| g.run(reporter) }.all?
          success ? 0 : @configuration.failure_exit_code
        end
      end
    end

    def run_in_parallel(example_groups, reporter)
      server = Server.new(reporter)
      workers = Workers.new
      workers.run_test_workers_with_server(server) do |worker, channel_to_server|
        client = Client.new(channel_to_server)
        index = 0
        RSpec.world.filtered_examples.each do |group, examples|
          examples.reject! do |example|
            index += 1
            (index % workers.number_of_workers) != (worker % workers.number_of_workers)
          end
        end
        success = example_groups.map { |g| g.run(client) }.all?
        client.result(success)
      end
      server.success?
    end
  end
end
