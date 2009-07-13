# Peeping is sort of an aspect-oriented programming module -- just without the fancy name
# It allows to hook class, instance and singleton methods for adding -and nicely managing-
# before and after procedures.
#
# Author::    Ruben Medellin  (mailto:ruben.medellin.c@gmail.com)
# License::   Distributes under the same terms as Ruby

require 'peeping/util'
require 'peeping/hook'
require 'peeping/exceptions'

# Wraps classes and modules for the +peeping+ library
module Peeping

  # This class defines the methods for hooking and unhooking methods, as well as contains the variables that
  # hold the hook definitions
  class Peep

    #--
    ## ========== Holder variables section ==========
    #++

    # Holds the hooks declared for class methods
    CLASS_METHOD_HOOKS      = {}

    # Holds the hooks defined for instance methods
    INSTANCE_METHOD_HOOKS   = {}

    # Holds the hooks defined for singleton methods
    SINGLETON_METHOD_HOOKS  = {}

    #--
    ## ===================================================
    ## =============== Class hooks section ===============
    ## ===================================================
    #++

    # Returns true if hooks given for class methods of the class +klass+ exist
    def self.is_class_hooked?(klass)
      CLASS_METHOD_HOOKS.has_key?(klass)
    end

    # Returns a hash containing all hooked methods for class +klass+ as keys, or an empty hash if don't exist
    def self.hooked_class_methods_for(klass)
      CLASS_METHOD_HOOKS[klass] || {}
    end

    # Adds +hooks+ hooks to the given +klass+ class methods +hooked_methods+
    # This parameter can be either a symbol or an array of symbols.
    #
    # Possible thrown exceptions:
    # NotAClassException::          When the specified parameter +klass+ is not a class
    # UndefinedMethodException::    When one of the symbols in +hooked_methods+ param is effectively not a defined class method
    # AlreadyDefinedHookException:: When a hook for this class and specified method exists
    # InvalidHooksException::       When hooks contains keys other than :before and :after calls
    def self.hook_class!(klass, hooked_methods, hooks)
      define_method_hooks!(klass, hooked_methods, hooks, :class, CLASS_METHOD_HOOKS)
    end

    # Removes hook class methods as well as returns the hooked methods to their original definition
    def self.unhook_class!(klass)
      klass.metaclass.class_eval do
        instance_methods.grep(/^__proxied_class_method_/).each do |proxied_method|
          proxied_method =~ (/^__proxied_class_method_(.*)$/)
          original = $1
          eval "alias #{original} #{proxied_method}"
          eval "undef #{proxied_method}"
        end
      end
      CLASS_METHOD_HOOKS.delete(klass)
    end

    #--
    ## ======================================================
    ## =============== Instance hooks section ===============
    ## ======================================================
    #++

    # Returns true if hooks given for instance methods of the class +klass+ exist
    def self.are_instances_hooked?(klass)
      INSTANCE_METHOD_HOOKS.has_key?(klass)
    end

    # Returns a hash containing all hooked methods for class +klass+ as keys, or an empty hash if don't exist
    def self.hooked_instance_methods_for(klass)
      INSTANCE_METHOD_HOOKS[klass] || {}
    end

    # Adds +hooks+ hooks to the given +klass+ instance methods +hooked_methods+
    # This parameter can be either a symbol or an array of symbols.
    #
    # Possible thrown exceptions:
    # NotAClassException::          When the specified parameter +klass+ is not a class
    # UndefinedMethodException::    When one of the symbols in +hooked_methods+ param is effectively not a defined instance method
    # AlreadyDefinedHookException:: When a hook for this class and specified instance method exists
    # InvalidHooksException::       When hooks contains keys other than :before and :after calls
    def self.hook_instances!(klass, hooked_methods, hooks)
      define_method_hooks!(klass, hooked_methods, hooks, :instance, INSTANCE_METHOD_HOOKS)
    end

    # Removes hook instance methods as well as returns the hooked methods to their original definition
    def self.unhook_instances!(klass)
      klass.class_eval do
        instance_methods.grep(/^__proxied_instance_method_/).each do |proxied_method|
          proxied_method =~ (/^__proxied_instance_method_(.*)$/)
          original = $1
          eval "alias #{original} #{proxied_method}"
          eval "undef #{proxied_method}"
        end
      end
      INSTANCE_METHOD_HOOKS.delete(klass)
    end

    #--
    ## =======================================================
    ## =============== Singleton hooks section ===============
    ## =======================================================
    #++

    # Returns true if hooks given for singleton methods of the class +klass+ exist
    def self.is_hooked?(object)
      SINGLETON_METHOD_HOOKS.has_key?(object)
    end

    # Returns a hash containing all hooked methods for class +klass+ as keys, or an empty hash if don't exist
    def self.hooked_singleton_methods_for(object)
      SINGLETON_METHOD_HOOKS[object] || {}
    end

    # Adds +hooks+ hooks to the given +object+ singleton methods +hooked_methods+
    # This parameter can be either a symbol or an array of symbols.
    #
    # Possible thrown exceptions:
    # UndefinedMethodException::    When one of the symbols in +hooked_methods+ param is not a defined method for object +object+
    # AlreadyDefinedHookException:: When a hook for this object and specified instance method exists.
    #                               Note that this error *will not* be raised if an instance method hook exists for this
    #                               method in the object's class. It will override it.
    # InvalidHooksException::       When hooks contains keys other than :before and :after calls
    def self.hook_object!(object, hooked_methods, hooks)
      define_method_hooks!(object, hooked_methods, hooks, :singleton, SINGLETON_METHOD_HOOKS)
    end

    # Removes hook singleton methods as well as returns the hooked methods to their original definition
    def self.unhook_object!(object)
      object.metaclass.class_eval do
        instance_methods.grep(/^__proxied_singleton_method_/).each do |proxied_method|
          proxied_method =~ (/^__proxied_singleton_method_(.*)$/)
          original = $1
          eval "alias #{original} #{proxied_method}"
          eval "undef #{proxied_method}"
        end
      end
      SINGLETON_METHOD_HOOKS.delete(object)
    end

    #--
    ## ========== Protected auxiliar methods section ==========
    class << self
      protected

      def define_method_hooks!(what, hooked_methods, hooks, mode, container)
        hooked_methods = [hooked_methods] if hooked_methods.is_a? Symbol

        validate_hooks(hooks)                     # Validate hooks
        validate_is_class(what, mode)             # Validate class

        where_to_eval = (mode == :class or mode == :singleton) ? what.metaclass : what
        hooked_methods.each do |hooked_method|    # Validate methods defined
          validate_has_method_defined(where_to_eval, hooked_method, mode)
        end

        hooked_methods.each do |hooked_method|
          container[what] ||= {}
          hooked_method_name = "__proxied_#{mode}_method_#{hooked_method}"

          if container[what].has_key?(hooked_method)
            raise AlreadyDefinedHookException.new("Hook signature present for #{hooked_method} in #{where_to_eval}")
          end
          if what.respond_to?(hooked_method_name)
            raise AlreadyDefinedHookException.new("Method #{hooked_method_name} hook already defined for #{hooked_method} in #{where_to_eval}")
          end

          container[what][hooked_method] = {}

          hooks.each do |where, callback|
            container[what][hooked_method][where] = callback
          end

          hook_key = (mode == :class or mode == :instance) ? what.name : 'self'
          before_hook_call = if hooks.include?(:before)
            "Peeping::Peep.hooked_#{mode}_methods_for(#{hook_key})[:\"#{hooked_method}\"][:before].call(self, *args)"
          end
          after_hook_call = if hooks.include?(:after)
            "Peeping::Peep.hooked_#{mode}_methods_for(#{hook_key})[:\"#{hooked_method}\"][:after].call(self, proxied_result)"
          end
          should_override_instance_call = (mode == :singleton).to_s
          class_eval_call = Proc.new do
            eval <<-REDEF
              if #{should_override_instance_call} and method_defined?(:"__proxied_instance_method_#{hooked_method}")
                alias :"#{hooked_method_name}" :"__proxied_instance_method_#{hooked_method}"
              else
                alias :"#{hooked_method_name}" :"#{hooked_method}"
              end
              def #{hooked_method}(*args, &block)
                #{before_hook_call}
                proxied_result = if block_given?
                  __send__("#{hooked_method_name}", *args, &block)
                else
                  __send__("#{hooked_method_name}", *args)
                end
                #{after_hook_call}
                proxied_result
              end
            REDEF
          end
          where_to_eval.class_eval(&class_eval_call)
        end
      end

      # Validates that the array consists only in the keys :before or/and :after
      #--
      # TODO: Add extensibility for possible keys. Ideas: warn_on_override, :dont_override, :execute_in_place
      #++
      def validate_hooks(hooks)
        raise InvalidHooksException.new("At least an :after or a :before hook are expected") if hooks.empty?
        unknown_keys = hooks.keys - [:before, :after]
        raise InvalidHooksException.new("Unknown keys #{unknown_keys.join(', ')}") unless unknown_keys.empty?
      end

      # Validates that the passed object is a class in :class and :instance modes
      def validate_is_class(what, mode)
        if mode == :class or mode == :instance
          raise NotAClassException.new("#{what} is not a Class") unless what.is_a? Class
        end
      end

      # Validates that the the method that will be hooked for the given object is defined.
      def validate_has_method_defined(holding_class, method, mode)
        unless holding_class.method_defined?(method)
          raise UndefinedMethodException.new("Undefined #{mode} method #{method.inspect} for #{holding_class}")
        end
      end
    end
    #++

  end

  ## ========== Auxiliar methods ==========

  class Peep
    # Completely removes all hooks for all defined classes and objects
    def self.clear_all_hooks!
      clear_all_class_hooks!
      clear_all_singleton_hooks!
      clear_all_instance_hooks!
    end

    #--
    class << self
      protected

      # TODO: Refactor lots of this

      def clear_all_class_hooks!
        Peep::CLASS_METHOD_HOOKS.each do |klass, hooked_methods|
          hooked_methods.each do |hooked_method, callbacks|
            klass.metaclass.class_eval <<-UNDEF_EVAL
              if method_defined?(:"__proxied_class_method_#{hooked_method}")
                alias :"#{hooked_method}" :"__proxied_class_method_#{hooked_method}"
                undef :"__proxied_class_method_#{hooked_method}"
              end
            UNDEF_EVAL
          end
        end
        Peep::CLASS_METHOD_HOOKS.clear
      end

      def clear_all_instance_hooks!
        Peep::INSTANCE_METHOD_HOOKS.each do |klass, hooked_methods|
          hooked_methods.each do |hooked_method, callbacks|
            klass.class_eval <<-UNDEF_EVAL
              if method_defined?(:"__proxied_instance_method_#{hooked_method}")
                alias :"#{hooked_method}" :"__proxied_instance_method_#{hooked_method}"
                undef :"__proxied_instance_method_#{hooked_method}"
              end
            UNDEF_EVAL
          end
        end
        Peep::INSTANCE_METHOD_HOOKS.clear
      end

      def clear_all_singleton_hooks!
        Peep::SINGLETON_METHOD_HOOKS.each do |object, hooked_methods|
          hooked_methods.each do |hooked_method, callbacks|
            object.metaclass.class_eval <<-UNDEF_EVAL
              if method_defined?(:"__proxied_singleton_method_#{hooked_method}")
                if method_defined?(:"__proxied_instance_method_#{hooked_method}")
                  alias :"#{hooked_method}" :"__proxied_instance_method_#{hooked_method}"
                else
                  alias :"#{hooked_method}" :"__proxied_singleton_method_#{hooked_method}"
                end
                undef :"__proxied_singleton_method_#{hooked_method}"
              end
            UNDEF_EVAL
          end
        end
        Peep::SINGLETON_METHOD_HOOKS.clear
      end
    end
    #++

  end    
end

