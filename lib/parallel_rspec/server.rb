module ParallelRSpec
  class Server
    attr_reader :reporter

    def initialize(reporter)
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

    def result(success, channel_to_client)
      @success &&= success
    end

    def success?
      @success
    end
  end
end
