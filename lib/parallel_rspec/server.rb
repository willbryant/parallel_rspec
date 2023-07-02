module ParallelRSpec
  class Server
    attr_reader :reporter, :remaining_examples_by_group, :running_examples

    def initialize(reporter)
      @remaining_examples_by_group = RSpec.world.filtered_examples.each_with_object({}) do |(example_group, examples), results|
        results[example_group] = examples unless example_group.any_context_hooks? || examples.size.zero?
      end
      @reporter = reporter
      @success = true
      @running_examples = {}
    end

    def example_started(example_id, example_updates, channel_to_client)
      reporter.example_started(update_example(running_examples[example_id], example_updates))
    end

    def example_finished(example_id, example_updates, channel_to_client)
      reporter.example_finished(update_example(running_examples[example_id], example_updates))
    end

    def example_passed(example_id, example_updates, channel_to_client)
      reporter.example_passed(update_example(running_examples.delete(example_id), example_updates))
    end

    def example_failed(example_id, example_updates, channel_to_client)
      reporter.example_failed(update_example(running_examples.delete(example_id), example_updates))
    end

    def example_pending(example_id, example_updates, channel_to_client)
      reporter.example_pending(update_example(running_examples.delete(example_id), example_updates))
    end

    def deprecation(hash, channel_to_client)
      reporter.deprecation(hash)
    end

    def next_example_to_run(channel_to_client)
      if remaining_examples_by_group.empty?
        channel_to_client.write(nil)
      else
        example_group = remaining_examples_by_group.keys.first
        example = remaining_examples_by_group[example_group].pop
        running_examples[example.id] = example # cache so we don't need to look through all the examples for each message
        channel_to_client.write([example_group, remaining_examples_by_group[example_group].size])
        remaining_examples_by_group.delete(example_group) if remaining_examples_by_group[example_group].empty?
      end
    end

    def result(success, channel_to_client)
      @success &&= success
    end

    def success?
      @success
    end

    def update_example(example, data)
      example.set_exception(data[:exception])
      example.metadata.merge!(data[:metadata])
      example
    end
  end
end
