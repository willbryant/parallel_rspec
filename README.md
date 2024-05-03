# ParallelRSpec

This gem lets you run your RSpec examples in parallel across across your CPUs.  Each worker gets its own database to avoid conflicts.

## Installation

Add this to your application's Gemfile:

```ruby
group :development, :test do
  gem 'parallel_rspec'
end
```

Or if you use Spring:

```ruby
group :development, :test do
  gem 'spring-prspec'
end
```

And then execute:

    $ bundle

This version of ParallelRSpec has been tested with RSpec 3.12.

## Usage

By default, ParallelRSpec will use four workers.  If you would like to use more, set an environment variable:

    $ export WORKERS=8

ParallelRSpec runs each worker with its own copy of the test database to avoid locking and deadlocking problems.  To create these and populate them with your schema, run:

    $ bundle exec rake parallel:create parallel:prepare

ParallelRSpec will automatically make the database name for each worker based on the name you used for the `test` environment in `config/database.yml`.  For example, if your normal `test` database is `foo_test`, worker 1 will keep using `foo_test` but worker 2's database will be `foo_test2`.

You're then ready to run specs in parallel:

    $ bundle exec prspec spec/my_spec.rb spec/another_spec.rb

Or if you use Spring:

    $ bundle exec spring prspec spec/my_spec.rb spec/another_spec.rb

You may like to make an alias:

    $ alias prspec='bundle exec spring prspec'
    $ prspec spec/my_spec.rb spec/another_spec.rb

When you change WORKERS, don't forget to restart Spring and re-run the create and populate steps above if necessary.

By default, there's a task called `parallel_rspec` which will run all specs. To make a custom rake task which uses parallel_rspec with different options, inherit from ParallelRSpec::RakeTask, for example:

```ruby
  require 'parallel_rspec'

  ParallelRSpec::RakeTask.new(:prspec) do |t|
    ENV['WORKERS'] = '8'
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = "--tag parallel"
    # etc...
  end
```

If you'd like code to run after parallel_rspec has created each worker, you can specify a block to run:

```ruby
  ParallelRSpec.configure do |config|
    config.after_fork do |worker_number|
      puts "I am worker #{worker_number}"
    end
  end
```

You might also want to detect whether your spec suite is running under ParallelRSpec or not:

```ruby
  do_something unless ParallelRSpec.running?
```

## Limitations

ParallelRSpec can't parallelize the specs in groups that use `before(:context)` or `after(:context)` (AKA `before(:all)` or `after(:all)`) hooks, since these may mean that there is state shared between examples.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/willbryant/parallel_rspec.


## Thanks

* Charles Horn (@hornc)
* Roger Nesbitt (@mogest)
* Erik Paasonen (@erikpaasonen)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) Powershop New Zealand Ltd, 2015.
Copyright (c) Will Bryant, 2023.
