# Changelog

## 2.6.0

* Fix `--profile` support. Thanks @peret.

## 2.5.0

* Update the RSpec example persistence file after each run. Thanks @bagedevimo.

## 2.4.2

* Fix more calls to deprecated `ActiveRecord::Base.configurations[]`.

## 2.4.1

* Exit workers promptly if asked to quit.

## 2.4.0

* Wrap Exception objects so they can always be dumped and loaded, even if they contain non-marshallable objects such as Procs or anonymous classes.

## 2.3.0

* Increase default workers from 2 to 4.
* Fix behavioral inconsistency with rspec-core in nested describe blocks on helper methods with clashing let methods.

## 2.2.0

* Fix incompatibility with `rspec --profile`.

## 2.1.2

* Fix error when used in projects without ActiveSupport. Thanks @erikpaasonen.

## 2.1.1

* Fix deprecation warnings from `ActiveRecord::Base.configurations[]`.

## 2.1.0

* Add a default parallel_rspec rake task.
* Add task descriptions for rake --tasks.

## 2.0.0

* Remove an unnecessary dev dependency to pacify dependabot.
* Add after_fork hook and running? method. Thanks @mogest.
* Upgrade for compatibility with Rails 6.1 and RSpec 3.10. Thanks @mogest.

## 1.2.0

* 9924295 Make the Railtie load optional.
* 6366f07 Add require to the recommended Rakefile for people not using Rails.
* 1a5ec3d Fix rake and rspec dependencies.
