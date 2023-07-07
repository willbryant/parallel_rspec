module ParallelRSpec
  # Some Exception objects contain non-marshallable ivars such as Proc objects. This wrapper
  # represents the bits needed by RSpec's ExceptionPresenter, and can be dumped and loaded.
  class ExceptionMarshallingWrapper < Exception
    attr_reader :class_name, :message, :backtrace, :cause

    def initialize(class_name, message, backtrace, cause)
      @class_name = class_name
      @message = message
      @backtrace = backtrace
      @cause = cause
    end

    def class
      eval "class #{@class_name}; end; #{@class_name}"
    end

    def inspect
      "#<#{@class_name}: #{@message}>"
    end

    def ==(other)
      other.is_a?(ExceptionMarshallingWrapper) &&
        class_name == other.class_name &&
        message == other.message &&
        backtrace == other.backtrace &&
        cause == other.cause
    end
  end

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
      example.execution_result.exception = dumpable_exception(example.execution_result.exception)
      {
        exception: dumpable_exception(example.exception),
        metadata: example.metadata.slice(
          :execution_result,
          :pending,
          :skip,
        )
      }
    end

    def dumpable_exception(exception)
      return exception if exception.nil? || exception.is_a?(ExceptionMarshallingWrapper)
      ExceptionMarshallingWrapper.new(exception.class.name, exception.to_s, exception.backtrace, dumpable_exception(exception.cause))
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
