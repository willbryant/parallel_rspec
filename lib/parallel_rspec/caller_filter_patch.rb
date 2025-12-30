require "rspec/support/caller_filter"

if RSpec.const_defined?(:CallerFilter) && RSpec::CallerFilter.const_defined?(:IGNORE_REGEX)
  module RSpec
    class CallerFilter
      _ignore_regex = Regexp.union(IGNORE_REGEX, "/lib/parallel_rspec", "parallel_rspec/exe/prspec")
      remove_const :IGNORE_REGEX
      IGNORE_REGEX = _ignore_regex
    end
  end
end
