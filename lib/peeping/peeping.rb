# Peeping is sort of an aspect-oriented programming module -- just without the fancy name
# It allows to hook class, instance and singleton methods for adding -and nicely managing-
# before and after procedures.
#
# Author::    Ruben Medellin  (mailto:ruben.medellin.c@gmail.com)
# License::   Distributes under the same terms as Ruby

require 'peeping/util'
require 'peeping/exceptions'

require 'peeping/hooks/class_hooks'
require 'peeping/hooks/instance_hooks'
require 'peeping/hooks/singleton_hooks'

# Wraps classes and modules for the +peeping+ library
module Peeping

  # This class defines the methods for hooking and unhooking methods, as well as contains the variables that
  # hold the hook definitions
  class Peep

    include ClassMethodHooks
    include InstanceMethodHooks
    include SingletonMethodHooks

    #--
    #===== GLOBAL FUNCTIONS =====
    #++

    # Completely removes all hooks for all defined classes and objects
    def self.clear_all_hooks!
      clear_all_singleton_hooks!
      clear_all_instance_hooks!
      clear_all_class_hooks!
    end

  end

end

