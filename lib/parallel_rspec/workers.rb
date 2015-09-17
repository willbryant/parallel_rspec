module ParallelRSpec
  class Workers
    def self.number_of_workers
      workers = ENV['WORKERS'].to_i
      workers = 4 if workers.zero?
      workers
    end

    attr_reader :number_of_workers

    def initialize(number_of_workers = Workers.number_of_workers)
      @number_of_workers = number_of_workers
    end

    def run_test_workers
      children = (1..number_of_workers).collect do |worker|
        fork do
          establish_test_database_connection(worker)
          yield worker
        end
      end

      verify_children(children)
    end

    def establish_test_database_connection(worker)
      ENV['TEST_ENV_NUMBER'] = worker.to_s
      ActiveRecord::Base.configurations['test']['database'] << worker.to_s unless worker.zero?
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
    end

    def verify_children(children)
      results = children.collect { |pid| Process.wait2(pid).last }.reject(&:success?)

      unless results.empty?
        STDERR.puts "\n#{results.size} worker#{'s' unless results.size == 1} failed"
        exit 1
      end
    end
  end
end
