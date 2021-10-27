module ParallelRSpec
  class Client
    attr_reader :channel_to_server

    def initialize(channel_to_server)
      @channel_to_server = channel_to_server
    end

    def example_group_started(group)
      # not implemented yet - would need the same extraction/simplification for serialization as Example below
    end

    def example_group_finished(group)
      # ditto
    end

    def example_started(example)
      channel_to_server.write([:example_started, serialize_example(example)])
    end

    def example_passed(example)
      channel_to_server.write([:example_passed, serialize_example(example)])
    end

    def example_failed(example)
      channel_to_server.write([:example_failed, serialize_example(example)])
    end

    def example_finished(example)
      channel_to_server.write([:example_finished, serialize_example(example)])
    end

    def example_pending(example)
      channel_to_server.write([:example_pending, serialize_example(example)])
    end

    def deprecation(hash)
      channel_to_server.write([:deprecation, hash])
    end

    def serialize_example(example)
      Example.new(
        example.id,
        example.description,
        example.exception,
        example.location_rerun_argument,
        ExampleGroup.new([]),
        example.metadata.slice(
          :absolute_file_path,
          :described_class,
          :description,
          :description_args,
          :execution_result,
          :full_description,
          :file_path,
          :last_run_status,
          :line_number,
          :location,
          :pending,
          :rerun_file_path,
          :scoped_id,
          :shared_group_inclusion_backtrace,
          :type))
    end

    def next_example_to_run
      channel_to_server.write([:next_example_to_run])
      channel_to_server.read
    end

    def result(success)
      channel_to_server.write([:result, success])
    end
  end
end
