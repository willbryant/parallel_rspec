module ParallelRSpec
  class Workers
    def self.number_of_workers
      workers = ENV['WORKERS'].to_i
      workers = 2 if workers.zero?
      workers
    end

    attr_reader :number_of_workers

    def initialize(number_of_workers = Workers.number_of_workers)
      @number_of_workers = number_of_workers
    end

    def run_test_workers
      child_pids = (1..number_of_workers).collect do |worker|
        fork do
          establish_test_database_connection(worker)
          yield worker
        end
      end

      verify_children(child_pids)
    end

    def run_test_workers_with_server(server)
      child_pids, channels = (1..number_of_workers).collect do |worker|
        channel_to_client, channel_to_server = ParallelRSpec::Channel.pipe

        pid = fork do
          channel_to_client.close
          establish_test_database_connection(worker)
          yield worker, channel_to_server
        end

        channel_to_server.close
        [pid, channel_to_client]
      end.transpose

      invoke_server_for_channels(server, channels)

      verify_children(child_pids)
    end

    def invoke_server_for_channels(server, channels)
      while !channels.empty?
        Channel.read_select(channels).each do |channel|
          if command = channel.read
            server.send(*(command + [channel]))
          else
            channels.delete(channel)
          end
        end
      end
    end

    def establish_test_database_connection(worker)
      if defined?(ActiveRecord)
        ENV['TEST_ENV_NUMBER'] = worker.to_s
        ActiveRecord::Base.configurations['test']['database'] << worker.to_s unless worker == 1
        ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      end
    end

    def verify_children(child_pids)
      results = child_pids.collect { |pid| Process.wait2(pid).last }.reject(&:success?)

      unless results.empty?
        STDERR.puts "\n#{results.size} worker#{'s' unless results.size == 1} failed"
        exit 1
      end
    end
  end
end
