gem "activesupport"
gem "activemodel"

require "active_support/core_ext/class/attribute_accessors"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/kernel/reporting"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/module/aliasing"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/core_ext/object/to_query"
require "active_support/core_ext/class/attribute"
require "active_support/json"

require "active_model"

module SuperModel
  class SuperModelError < StandardError; end
  class UnknownRecord < SuperModelError; end
  class InvalidRecord < SuperModelError; end
end

$:.unshift(File.dirname(__FILE__))
require "supermodel/ext/array"

module SuperModel
  autoload :Association, "supermodel/association"
  autoload :Callbacks,   "supermodel/callbacks"
  autoload :Observing,   "supermodel/observing"
  autoload :Marshal,     "supermodel/marshal"
  autoload :RandomID,    "supermodel/random_id"
  autoload :Timestamp,   "supermodel/timestamp"
  autoload :Validations, "supermodel/validations"
  autoload :Dirty,       "supermodel/dirty"
  autoload :Redis,       "supermodel/redis"
  autoload :Base,        "supermodel/base"
end