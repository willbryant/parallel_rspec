# Changelog

## 2.1.2

* Fix error when used in projects without ActiveSupport. Thanks @erikpaasonen.

## 2.1.1

* Fix deprecation warnings from ActiveRecord::Base.configurations[].

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
