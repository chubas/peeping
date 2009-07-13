# peeping

Like aspect-oriented, but cooler!

## Motivation

This library intends to provide a simple yet flexible way for defining hook calls for your methods,
without trying to be a complete aspect-oriented programming framework implementation.

## Installation

Just point to the root directory of the library in your require path and include `peeping.rb` (Gem packaging soon)

## Usage

For defining hooks, use the methods of `Peeping::Peep` class

    include Peeping

    class Foo
      def some_instance_method
        puts "Hi there!"
      end
      def self.some_class_method
        puts "Cool!"
      end
    end

    foo = Foo.new

    Peep.hook_class!(Foo, :some_class_method,
            :before => Proc.new{ puts "Before class method" },
            :after  => Proc.new{ puts "After class method" })
    Peep.hook_instances!(Foo, :some_instance_method,
            :before => Proc.new{ puts "Before instance method" },
            :after  => Proc.new{ puts "After instance method" })
    Peep.hook_object!(foo, :some_instance_method,
            :before => Proc.new{ puts "Before singleton instance method" },
            :after  => Proc.new{ puts "After singleton instance method" })

    Foo.some_class_method
    Foo.new.some_instance_method
    foo.some_instance_method

produces output:

     Before class method
     Cool!
     After class method
     Before instance method
     Hi there!
     After instance method
     Before singleton instance method
     Hi there!
     After singleton instance method


[See documentation online][1] and TODO notes for more info

## Tests

The library comes with its rspec test suite, located in folder _tests_ 

## Updates

## TODO

- Add option to eval in the context of the caller with instance_exec
- Selective remove for existing hooks
- Add option to either replace or wrap singleton method hooks when instance method hooks are already defined
- Accept options for wrapping, replacing or adding hooks at custom positions in the bubble chain
- Gem packaging

  [1]: http://rdoc.info/projects/chubas/peeping