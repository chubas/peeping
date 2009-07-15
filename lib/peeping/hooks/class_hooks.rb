require 'peeping/hooks/hooking'

module Peeping
  module ClassMethodHooks

    #--
    # Extend class and instance methods to the base class
    #++
    def self.included(base) #:nodoc:
      base.extend Peeping::ClassMethodHooks::ClassMethods
      base.class_eval do
        include Peeping::ClassMethodHooks::InstanceMethods
      end
    end
  
    module ClassMethods

      include Hooking
      
      # Holds the hooks declared for class methods
      CLASS_METHOD_HOOKS      = {}

      # Returns true if hooks given for class methods of the class +klass+ exist
      def is_class_hooked?(klass)
        CLASS_METHOD_HOOKS.has_key?(klass) and not CLASS_METHOD_HOOKS[klass].empty?
      end

      # Returns a hash containing all hooked methods for class +klass+ as keys, or an empty hash if don't exist
      def hooked_class_methods_for(klass)
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
      def hook_class!(klass, hooked_methods, hooks)

        hooked_methods = [hooked_methods] if hooked_methods.is_a? Symbol

        validate_hooks(hooks)     # Validate hooks
        validate_is_class(klass)  # Validate class

        hooked_methods.each do |hooked_method|    # Validate methods defined
          validate_has_method_defined(klass.metaclass, hooked_method)
        end

        hooked_methods.each do |hooked_method|
          CLASS_METHOD_HOOKS[klass] ||= {}
          new_hooked_method_name = "#{CLASS_HOOK_METHOD_PREFIX}#{hooked_method}"

          if CLASS_METHOD_HOOKS[klass].has_key?(hooked_method)
            raise AlreadyDefinedHookException.new("Hook signature present for #{hooked_method} in #{klass.metaclass}")
          end
          if klass.metaclass.method_defined?(new_hooked_method_name)
            raise AlreadyDefinedHookException.new("Method #{new_hooked_method_name} hook already defined for #{hooked_method} in #{klass.metaclass}")
          end

          CLASS_METHOD_HOOKS[klass][hooked_method] = {}

          hooks.each do |where, callback|
            CLASS_METHOD_HOOKS[klass][hooked_method][where] = callback
          end

          hook_key = klass.name
          before_hook_call = <<-BEFORE_HOOK_CALL
            before_hook_callback = Peeping::Peep.hooked_class_methods_for(#{hook_key})[:"#{hooked_method}"][:before]
            before_hook_callback.call(self, *args) if before_hook_callback
          BEFORE_HOOK_CALL

          after_hook_call = <<-AFTER_HOOK_CALL
            after_hook_callback = Peeping::Peep.hooked_class_methods_for(#{hook_key})[:"#{hooked_method}"][:after]
            after_hook_callback.call(self, proxied_result) if after_hook_callback
          AFTER_HOOK_CALL

          class_eval_call = Proc.new do
            eval <<-REDEF
              alias :"#{new_hooked_method_name}" :"#{hooked_method}"
              def #{hooked_method}(*args, &block)
                #{before_hook_call}
                proxied_result = if block_given?
                  __send__("#{new_hooked_method_name}", *args, &block)
                else
                  __send__("#{new_hooked_method_name}", *args)
                end
                #{after_hook_call}
                proxied_result
              end
            REDEF
          end
          klass.metaclass.class_eval(&class_eval_call)
        end
      end

      # Removes hook class methods as well as returns the hooked methods to their original definition
      def unhook_class!(klass, methods = :all, hooks = :all)
        methods = (methods == :all) ? CLASS_METHOD_HOOKS[klass].keys : (methods.is_a?(Symbol) ? [methods] : methods)
        raise ArgumentError("Valid arguments: :before, :after or :all") unless [:before, :after, :all].include?(hooks)

        # Validate all methods exist before doing anything 
        methods.each do |method|
          raise UndefinedHookException.new("No hook defined for class method #{method})") unless CLASS_METHOD_HOOKS[klass][method]
        end

        methods.each do |method|
          if hooks == :all
            klass.metaclass.class_eval <<-REDEF_OLD_METHOD
              alias :"#{method}" :"#{CLASS_HOOK_METHOD_PREFIX}#{method}"
              undef :"#{CLASS_HOOK_METHOD_PREFIX}#{method}"
            REDEF_OLD_METHOD
            CLASS_METHOD_HOOKS[klass].delete(method)
          else
            unless CLASS_METHOD_HOOKS[klass][method][hooks]
              raise UndefinedHookException.new("No hook defined for class method #{method}) at #{hooks.inspect}")
            end
            CLASS_METHOD_HOOKS[klass][method].delete(hooks)
            CLASS_METHOD_HOOKS[klass].delete(method) if CLASS_METHOD_HOOKS[klass][method].empty?
          end
        end

        CLASS_METHOD_HOOKS.delete(klass) if methods == :all or (CLASS_METHOD_HOOKS[klass] || {}).empty?

      end

      def clear_all_class_hooks!
        CLASS_METHOD_HOOKS.each do |klass, hooked_methods|
          hooked_methods.each do |hooked_method, callbacks|
            redefined_method = "#{CLASS_HOOK_METHOD_PREFIX}#{hooked_method}"
            klass.metaclass.class_eval <<-UNDEF_EVAL
              if method_defined?(:"#{redefined_method}")
                alias :"#{hooked_method}" :"#{redefined_method}"
                undef :"#{redefined_method}"
              end
            UNDEF_EVAL
          end
        end
        CLASS_METHOD_HOOKS.clear
      end

    end

    module InstanceMethods
    end

  end
end