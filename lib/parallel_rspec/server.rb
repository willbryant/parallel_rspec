module ParallelRSpec
  class Server
    attr_reader :remaining_example_group_indexes, :reporter

    def initialize(reporter)
      @remaining_example_group_indexes = RSpec.world.filtered_examples.each_with_object({}) do |(example_group, examples), results|
        results[example_group] = examples.size unless example_group.any_context_hooks? || examples.size.zero?
      end
      @reporter = reporter
      @success = true
    end

    def example_started(example, channel_to_client)
      reporter.example_started(example)
    end

    def example_passed(example, channel_to_client)
      reporter.example_passed(example)
    end

    def example_failed(example, channel_to_client)
      reporter.example_failed(example)
    end

    def example_pending(example, channel_to_client)
      reporter.example_pending(example)
    end

    def deprecation(hash, channel_to_client)
      reporter.deprecation(hash)
    end

    def next_example_to_run(channel_to_client)
      if remaining_example_group_indexes.empty?
        channel_to_client.write(nil)
      else
        klass = remaining_example_group_indexes.keys.first
        remaining_example_group_indexes[klass] -= 1
        channel_to_client.write([klass, remaining_example_group_indexes[klass]])
        remaining_example_group_indexes.delete(klass) if remaining_example_group_indexes[klass].zero?
      end
    end

    def result(success, channel_to_client)
      @success &&= success
    end

    def success?
      @success
    end
  end
end
