require "simplecov"
require "parallel_rspec/config"

module ParallelRSpec
  @simplecov_enabled = false
  @simplecov_base_dir = nil
  @simplecov_formatters = nil

  def self.simplecov_enabled?
    @simplecov_enabled
  end

  def self.simplecov(profile = nil, formatters: nil, &block)
    ::SimpleCov.enable_for_subprocesses true

    base_dir = ::SimpleCov.coverage_dir

    force_worker_settings = lambda do
      # Prevent forked processes races generating the HTML report; each
      # process just dumps a .resultset.json that the runner collates into
      # the user's chosen formatter(s) at the end of the run.
      ::SimpleCov.print_error_status = false
      ::SimpleCov.formatter ::SimpleCov::Formatter::SimpleFormatter
      ::SimpleCov.minimum_coverage 0
    end

    start_simplecov = lambda do |command_name, dir|
      ::SimpleCov.command_name command_name
      ::SimpleCov.coverage_dir dir
      ::SimpleCov.start(profile, &block)
    end

    ParallelRSpec::Config.after_fork do |worker_number|
      force_worker_settings.call
      start_simplecov.call(
        "RSpec Worker #{worker_number}",
        File.join(base_dir, "rspec_#{worker_number}"),
      )
    end

    force_worker_settings.call
    start_simplecov.call("RSpec Server", File.join(base_dir, "rspec_server"))

    @simplecov_base_dir = base_dir
    @simplecov_formatters = formatters
    @simplecov_enabled = true
  end

  def self.collate_simplecov!
    base_dir = @simplecov_base_dir || ::SimpleCov.coverage_dir

    # Force the server process's resultset to disk before we glob. SimpleCov's
    # own at_exit handler will harmlessly re-dump it after collation finishes.
    ::SimpleCov.result.format!

    pattern = File.join(base_dir, "rspec_*", ".resultset.json")
    resultsets = Dir.glob(pattern)

    if resultsets.empty?
      warn "[parallel_rspec] no SimpleCov resultsets found under #{pattern}; skipping collation"
      return
    end

    collate_formatter =
      case (@simplecov_formatters || []).length
      when 0 then nil
      when 1 then @simplecov_formatters.first
      else ::SimpleCov::Formatter::MultiFormatter.new(@simplecov_formatters)
      end

    puts "Collating #{resultsets.size} SimpleCov resultset(s)..."

    ::SimpleCov.collate(resultsets) do
      coverage_dir base_dir
      formatter collate_formatter if collate_formatter
    end
  rescue => e
    warn "[parallel_rspec] simplecov collation failed: #{e.class}: #{e.message}"
  end
end
