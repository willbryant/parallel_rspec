module ParallelRSpec
  class Server
    attr_reader :reporter

    def initialize(reporter)
      @reporter = reporter
      @success = true
    end

    def example_started(example)
      reporter.example_started(example)
    end

    def example_passed(example)
      reporter.example_passed(example)
    end

    def example_failed(example)
      reporter.example_failed(example)
    end

    def example_pending(example)
      reporter.example_pending(example)
    end

    def deprecation(hash)
      reporter.deprecation(hash)
    end

    def result(result)
      @success &&= result
    end

    def success?
      @success
    end
  end
end
