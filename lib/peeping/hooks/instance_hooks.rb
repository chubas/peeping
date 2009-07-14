require 'peeping/hooks/hooking'

module Peeping
  module InstanceMethodHooks

    def self.included(base)
      base.extend Peeping::InstanceMethodHooks::ClassMethods
      base.class_eval do
        include Peeping::InstanceMethodHooks::InstanceMethods
      end
    end

    module ClassMethods

      include Hooking

      # Holds the hooks defined for instance methods
      INSTANCE_METHOD_HOOKS   = {}   

      # Returns true if hooks given for instance methods of the class +klass+ exist
      def are_instances_hooked?(klass)
        INSTANCE_METHOD_HOOKS.has_key?(klass)
      end

      # Returns a hash containing all hooked methods for class +klass+ as keys, or an empty hash if don't exist
      def hooked_instance_methods_for(klass)
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
      def hook_instances!(klass, hooked_methods, hooks)
        hooked_methods = [hooked_methods] if hooked_methods.is_a? Symbol

        validate_hooks(hooks)                     # Validate hooks
        validate_is_class(klass)                   # Validate class

        hooked_methods.each do |hooked_method|    # Validate methods defined
          validate_has_method_defined(klass, hooked_method)
        end

        hooked_methods.each do |hooked_method|
          INSTANCE_METHOD_HOOKS[klass] ||= {}
          hooked_method_name = "#{INSTANCE_HOOK_METHOD_PREFIX}#{hooked_method}"

          if INSTANCE_METHOD_HOOKS[klass].has_key?(hooked_method)
            raise AlreadyDefinedHookException.new("Hook signature present for #{hooked_method} in #{klass}")
          end
          if klass.respond_to?(hooked_method_name)
            raise AlreadyDefinedHookException.new("Method #{hooked_method_name} hook already defined for #{hooked_method} in #{where_to_eval}")
          end

          INSTANCE_METHOD_HOOKS[klass][hooked_method] = {}

          hooks.each do |where, callback|
            INSTANCE_METHOD_HOOKS[klass][hooked_method][where] = callback
          end

          hook_key = klass.name
          before_hook_call = if hooks.include?(:before)
            "Peeping::Peep.hooked_instance_methods_for(#{hook_key})[:\"#{hooked_method}\"][:before].call(self, *args)"
          end
          after_hook_call = if hooks.include?(:after)
            "Peeping::Peep.hooked_instance_methods_for(#{hook_key})[:\"#{hooked_method}\"][:after].call(self, proxied_result)"
          end
          class_eval_call = Proc.new do
            eval <<-REDEF
              alias :"#{hooked_method_name}" :"#{hooked_method}"
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
          klass.class_eval(&class_eval_call)
        end
        
      end

      # Removes hook instance methods as well as returns the hooked methods to their original definition
      def unhook_instances!(klass)
        klass.class_eval do
          instance_methods.grep(/^#{CLASS_HOOK_METHOD_PREFIX}/).each do |proxied_method|
            proxied_method =~ (/^#{CLASS_HOOK_METHOD_PREFIX}(.*)$/)
            original = $1
            eval "alias #{original} #{proxied_method}"
            eval "undef #{proxied_method}"
          end
        end
        INSTANCE_METHOD_HOOKS.delete(klass)
      end

      def clear_all_instance_hooks!
        INSTANCE_METHOD_HOOKS.each do |klass, hooked_methods|
          hooked_methods.each do |hooked_method, callbacks|
            redefined_method = "#{INSTANCE_HOOK_METHOD_PREFIX}#{hooked_method}"
            klass.class_eval <<-UNDEF_EVAL
              if method_defined?(:"#{redefined_method}")
                alias :"#{hooked_method}" :"#{redefined_method}"
                undef :"#{redefined_method}"
              end
            UNDEF_EVAL
          end
        end
        INSTANCE_METHOD_HOOKS.clear
      end

    end

    module InstanceMethods
    end

  end
end