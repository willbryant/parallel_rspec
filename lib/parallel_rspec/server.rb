module ParallelRSpec
  class Server
    attr_reader :reporter, :remaining_examples_by_group, :running_examples, :top_level_groups

    def initialize(reporter)
      @remaining_examples_by_group = RSpec.world.filtered_examples.each_with_object({}) do |(example_group, examples), results|
        results[example_group] = examples unless example_group.any_context_hooks? || examples.size.zero?
      end
      @reporter = reporter
      @success = true
      @running_examples = {}
      @top_level_groups = @remaining_examples_by_group.each_with_object({}) do |(group, examples), results|
        results[top_level(group)] ||= { started: false, count: 0 }
        results[top_level(group)][:count] += examples.size
      end
    end

    def report_example_group_started(group)
      top_level_group = top_level(group)
      return if top_level_groups[top_level_group][:started] # already reported as started

      top_level_groups[top_level_group][:started] = true
      reporter.example_group_started(top_level_group)
    end

    def report_example_group_finished(group)
      top_level_group = top_level(group)
      top_level_groups[top_level_group][:count] -= 1
      reporter.example_group_finished(top_level_group) if top_level_groups[top_level_group][:count].zero?
    end

    def example_started(example_id, example_updates, channel_to_client)
      reporter.example_started(update_example(running_examples[example_id], example_updates))
      report_example_group_started(running_examples[example_id].example_group)
    end

    def example_finished(example_id, example_updates, channel_to_client)
      reporter.example_finished(update_example(running_examples[example_id], example_updates))
      report_example_group_finished(running_examples[example_id].example_group)
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

    private

    def top_level(example_group)
      example_group.parent_groups.last
    end
  end
end
