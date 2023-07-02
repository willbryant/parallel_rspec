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
      channel_to_server.write([:example_started, example.id, updates_from(example)])
    end

    def example_passed(example)
      channel_to_server.write([:example_passed, example.id, updates_from(example)])
    end

    def example_failed(example)
      channel_to_server.write([:example_failed, example.id, updates_from(example)])
    end

    def example_finished(example)
      channel_to_server.write([:example_finished, example.id, updates_from(example)])
    end

    def example_pending(example)
      channel_to_server.write([:example_pending, example.id, updates_from(example)])
    end

    def deprecation(hash)
      channel_to_server.write([:deprecation, hash])
    end

    def updates_from(example)
      {
        exception: example.exception,
        metadata: example.metadata.slice(
          :execution_result,
          :pending,
          :skip,
        )
      }
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
