require 'peeping/exceptions'

module Peeping
  module Hooking

    HOOKED_METHOD_PREFIX = '__peeping__hooked'

    # Prefix for hooked class methods
    CLASS_HOOK_METHOD_PREFIX      = "#{HOOKED_METHOD_PREFIX}__class__method__"

    # Prefix for hooked class methods
    INSTANCE_HOOK_METHOD_PREFIX   = "#{HOOKED_METHOD_PREFIX}__instance__method__"

    # Prefix for hooked class methods
    SINGLETON_HOOK_METHOD_PREFIX  = "#{HOOKED_METHOD_PREFIX}__singleton__method__"

    private

    # Validates that the array consists only in the keys :before or/and :after
    #--
    # TODO: Add extensibility for possible keys. Ideas: warn_on_override, :dont_override, :execute_in_place
    #++
    def validate_hooks(hooks)
      raise InvalidHooksException.new("At least an :after or a :before hook are expected") if hooks.empty?
      unknown_keys = hooks.keys - [:before, :after]
      raise InvalidHooksException.new("Unknown keys #{unknown_keys.join(', ')}") unless unknown_keys.empty?
    end

    # Validates that the passed object is a class
    def validate_is_class(klass)
      raise NotAClassException.new("#{klass} is not a Class") unless klass.is_a? Class
    end

    # Validates that the the method that will be hooked for the given object is defined.
    def validate_has_method_defined(holding_class, method)
      unless holding_class.method_defined?(method)
        raise UndefinedMethodException.new("Undefined method #{method.inspect} for #{holding_class}")
      end
    end

  end
end