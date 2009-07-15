require 'peeping/hooks/hooking'

module Peeping
  module SingletonMethodHooks

    #--
    # Extend class and instance methods to the base class
    #++
    def self.included(base) #:nodoc:
      base.extend Peeping::SingletonMethodHooks::ClassMethods
      base.class_eval do
        include Peeping::SingletonMethodHooks::InstanceMethods
      end
    end

    module ClassMethods

      include Hooking

      # Holds the hooks defined for instance methods
      SINGLETON_METHOD_HOOKS   = {}  

      # Returns true if hooks given for singleton methods of the class +klass+ exist
      def is_hooked?(object)
        SINGLETON_METHOD_HOOKS.has_key?(object)
      end

      # Returns a hash containing all hooked methods for class +klass+ as keys, or an empty hash if don't exist
      def hooked_singleton_methods_for(object)
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
      def hook_object!(object, hooked_methods, hooks)
        hooked_methods = [hooked_methods] if hooked_methods.is_a? Symbol

        validate_hooks(hooks)                     # Validate hooks

        hooked_methods.each do |hooked_method|    # Validate methods defined
          validate_has_method_defined(object.metaclass, hooked_method)
        end

        hooked_methods.each do |hooked_method|
          SINGLETON_METHOD_HOOKS[object] ||= {}
          hooked_method_name = "#{SINGLETON_HOOK_METHOD_PREFIX}#{hooked_method}"

          if SINGLETON_METHOD_HOOKS[object].has_key?(hooked_method)
            raise AlreadyDefinedHookException.new("Hook signature present for #{hooked_method} in #{object.metaclass}")
          end
          if object.metaclass.method_defined?(hooked_method_name)
            raise AlreadyDefinedHookException.new("Method #{hooked_method_name} hook already defined for #{hooked_method} in #{where_to_eval}")
          end

          SINGLETON_METHOD_HOOKS[object][hooked_method] = {}

          hooks.each do |where, callback|
            SINGLETON_METHOD_HOOKS[object][hooked_method][where] = callback
          end

          hook_key = 'self'
          before_hook_call = <<-BEFORE_HOOK_CALL

            before_hook_callback = Peeping::Peep.hooked_singleton_methods_for(#{hook_key})[:"#{hooked_method}"][:before]
            instance_before_hook_callback = ((Peeping::Peep.hooked_instance_methods_for(self.class) || {})[:"#{hooked_method}"] || {})[:before]

            before_hook_callback ||= instance_before_hook_callback                      
            before_hook_callback.call(self, *args) if before_hook_callback
          BEFORE_HOOK_CALL

          after_hook_call = <<-AFTER_HOOK_CALL
            after_hook_callback = Peeping::Peep.hooked_singleton_methods_for(#{hook_key})[:"#{hooked_method}"][:after]
            instance_after_hook_callback = ((Peeping::Peep.hooked_instance_methods_for(self.class) || {})[:"#{hooked_method}"] || {})[:after]

            after_hook_callback ||= instance_after_hook_callback  
            after_hook_callback.call(self, proxied_result) if after_hook_callback
          AFTER_HOOK_CALL

          should_override_instance_call = true # TODO: Optionalize
          class_eval_call = Proc.new do
            eval <<-REDEF
              if #{should_override_instance_call} and method_defined?(:"#{INSTANCE_HOOK_METHOD_PREFIX}#{hooked_method}")
                alias :"#{hooked_method_name}" :"#{INSTANCE_HOOK_METHOD_PREFIX}#{hooked_method}"
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
          object.metaclass.class_eval(&class_eval_call)
        end
      end

      # Removes hook singleton methods as well as returns the hooked methods to their original definition
      def unhook_object!(object, methods = :all, hooks = :all)
        methods = (methods == :all) ? SINGLETON_METHOD_HOOKS[object].keys : (methods.is_a?(Symbol) ? [methods] : methods)
        raise ArgumentError("Valid arguments: :before, :after or :all") unless [:before, :after, :all].include?(hooks)

        # Validate all methods exist before doing anything
        methods.each do |method|
          raise UndefinedHookException.new("No hook defined for class method #{method})") unless SINGLETON_METHOD_HOOKS[object][method]
        end

        methods.each do |method|
          if hooks == :all
            x = <<-REDEF_OLD_METHOD
              alias :"#{method}" :"#{SINGLETON_HOOK_METHOD_PREFIX}#{method}"
              undef :"#{SINGLETON_HOOK_METHOD_PREFIX}#{method}"
            REDEF_OLD_METHOD
            puts x
            object.metaclass.class_eval x
            SINGLETON_METHOD_HOOKS[object].delete(method)
          else
            unless SINGLETON_METHOD_HOOKS[object][method][hooks]
              raise UndefinedHookException.new("No hook defined for singleton method #{method}) at #{hooks.inspect}")
            end
            SINGLETON_METHOD_HOOKS[object][method].delete(hooks)
            SINGLETON_METHOD_HOOKS[object].delete(method) if SINGLETON_METHOD_HOOKS[object][method].empty?
          end
        end

        SINGLETON_METHOD_HOOKS.delete(object) if methods == :all or (SINGLETON_METHOD_HOOKS[object] || {}).empty?
      end

      def clear_all_singleton_hooks!
        SINGLETON_METHOD_HOOKS.each do |object, hooked_methods|
          hooked_methods.each do |hooked_method, callbacks|
            redefined_singleton_method  = "#{SINGLETON_HOOK_METHOD_PREFIX}#{hooked_method}"
            redefined_instance_method   = "#{INSTANCE_HOOK_METHOD_PREFIX}#{hooked_method}"
            object.metaclass.class_eval <<-UNDEF_EVAL
              if method_defined?(:"#{redefined_singleton_method}")
                if method_defined?(:"#{redefined_instance_method}")
                  alias :"#{hooked_method}" :"#{redefined_instance_method}"
                else
                  alias :"#{hooked_method}" :"#{redefined_singleton_method}"
                end
                undef :"#{redefined_singleton_method}"
              end
            UNDEF_EVAL
          end
        end
        SINGLETON_METHOD_HOOKS.clear
      end

    end

    module InstanceMethods
    end

  end
end
