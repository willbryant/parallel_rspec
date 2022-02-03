require 'parallel_rspec/workers.rb'

db_namespace = namespace :db do
  namespace :parallel do
    desc "Creates the test databases"
    task :create => [:load_config] do
      ParallelRSpec::Workers.new.run_test_workers do |worker|
        ActiveRecord::Tasks::DatabaseTasks.create ActiveRecord::Base.configurations['test']
      end
    end

    desc "Empty the test databases"
    task :purge => %w(environment load_config) do
      ParallelRSpec::Workers.new.run_test_workers do |worker|
        ActiveRecord::Tasks::DatabaseTasks.purge ActiveRecord::Base.configurations['test']
      end
    end

    desc "Recreate the test databases from an existent schema.rb file"
    task :load_schema => %w(db:parallel:purge) do
      should_reconnect = ActiveRecord::Base.connection_pool.active_connection?
      begin
        ParallelRSpec::Workers.new.run_test_workers do |worker|
          ActiveRecord::Schema.verbose = false
          if ActiveRecord::Tasks::DatabaseTasks.respond_to?(:load_schema_current)
            ActiveRecord::Tasks::DatabaseTasks.load_schema_current :ruby, ENV['SCHEMA'], 'test'
          else
            ActiveRecord::Tasks::DatabaseTasks.load_schema_for ActiveRecord::Base.configurations['test'], :ruby, ENV['SCHEMA']
          end
        end
      ensure
        if should_reconnect
          ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
        end
      end
    end

    desc "Recreate the test databases from an existent structure.sql file"
    task :load_structure => %w(db:parallel:purge) do
      ParallelRSpec::Workers.new.run_test_workers do |worker|
        if ActiveRecord::Tasks::DatabaseTasks.respond_to?(:load_schema_current)
          ActiveRecord::Tasks::DatabaseTasks.load_schema_current :sql, ENV['SCHEMA'], 'test'
        else
          ActiveRecord::Tasks::DatabaseTasks.load_schema_for ActiveRecord::Base.configurations['test'], :sql, ENV['SCHEMA']
        end
      end
    end

    desc "Recreate the test databases from the current schema"
    task :load do
      db_namespace["parallel:purge"].invoke
      case ActiveRecord::Base.schema_format
      when :ruby
        db_namespace["parallel:load_schema"].invoke
      when :sql
        db_namespace["parallel:load_structure"].invoke
      end
    end

    desc "Check for pending migrations and load the test schema"
    task :prepare => %w(environment load_config) do
      unless ActiveRecord::Base.configurations.blank?
        db_namespace['parallel:load'].invoke
      end
    end
  end
end

ParallelRSpec::RakeTask.new(:parallel_rspec) do |t|
  t.pattern = "spec/**/*_spec.rb"
end
