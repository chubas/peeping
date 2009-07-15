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

        #=== Validations ===
        validate_hooks(hooks)
        validate_is_class(klass)
        hooked_methods.each { |hooked_method| validate_has_method_defined(klass, hooked_method) }

        hooked_methods.each do |hooked_method|
          INSTANCE_METHOD_HOOKS[klass] ||= {}
          hooked_method_name = "#{INSTANCE_HOOK_METHOD_PREFIX}#{hooked_method}"

          if INSTANCE_METHOD_HOOKS[klass].has_key?(hooked_method)
            raise AlreadyDefinedHookException.new("Hook signature present for #{hooked_method} in #{klass}")
          end
          if klass.method_defined?(hooked_method_name)
            raise AlreadyDefinedHookException.new("Method #{hooked_method_name} hook already defined for #{hooked_method} in #{klass}")
          end

          INSTANCE_METHOD_HOOKS[klass][hooked_method] = {}

          hooks.each do |where, callback|
            INSTANCE_METHOD_HOOKS[klass][hooked_method][where] = callback
          end

          hook_key = klass.name
          before_hook_call = <<-BEFORE_HOOK_CALL
            before_hook_callback = Peeping::Peep.hooked_instance_methods_for(#{hook_key})[:"#{hooked_method}"][:before]
            before_hook_callback.call(self, *args) if before_hook_callback
          BEFORE_HOOK_CALL

          after_hook_call = <<-AFTER_HOOK_CALL
            after_hook_callback = Peeping::Peep.hooked_instance_methods_for(#{hook_key})[:"#{hooked_method}"][:after]
            after_hook_callback.call(self, proxied_result) if after_hook_callback
          AFTER_HOOK_CALL

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
      def unhook_instances!(klass, methods = :all, hooks = :all)
        methods = (methods == :all) ? INSTANCE_METHOD_HOOKS[klass].keys : (methods.is_a?(Symbol) ? [methods] : methods)
        raise ArgumentError("Valid arguments: :before, :after or :all") unless [:before, :after, :all].include?(hooks)

        # Validate all methods exist before doing anything
        methods.each do |method|
          raise UndefinedHookException.new("No hook defined for instance method #{method})") unless INSTANCE_METHOD_HOOKS[klass][method]
        end

        methods.each do |method|
          if hooks == :all
            klass.class_eval <<-REDEF_OLD_METHOD
              alias :"#{method}" :"#{INSTANCE_HOOK_METHOD_PREFIX}#{method}"
              undef :"#{INSTANCE_HOOK_METHOD_PREFIX}#{method}"
            REDEF_OLD_METHOD
            INSTANCE_METHOD_HOOKS[klass].delete(method)
          else
            unless INSTANCE_METHOD_HOOKS[klass][method][hooks]
              raise UndefinedHookException.new("No hook defined for instance method #{method}) at #{hooks.inspect}")
            end
            INSTANCE_METHOD_HOOKS[klass][method].delete(hooks)
            INSTANCE_METHOD_HOOKS[klass].delete(method) if INSTANCE_METHOD_HOOKS[klass][method].empty?
          end
        end

        INSTANCE_METHOD_HOOKS.delete(klass) if methods == :all or (INSTANCE_METHOD_HOOKS[klass] || {}).empty?

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