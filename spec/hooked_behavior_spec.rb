require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'peeping')
require File.join(File.dirname(__FILE__), 'helpers', 'test_helpers')

include Peeping

describe Peep, "when calling hook methods" do

  it_should_behave_like "a clean test"

  it "should evaluate class proc calls" do
    before_class_hook_called  = false
    after_class_hook_called   = false
    Peep.hook_class!(
            Dog,
            :eats?,
            :before => Proc.new{|*args| before_class_hook_called = true },
            :after  => Proc.new{|*args| after_class_hook_called  = true }   )
    Dog.eats?('french fries')
    before_class_hook_called.should == true
    after_class_hook_called.should  == true
  end

  it "should evaluate instance proc calls" do
    before_instance_hook_called = false
    after_instance_hook_called  = false
    Peep.hook_instances!(
            Dog,
            :bark,
            :before => Proc.new{|*args| before_instance_hook_called = true},
            :after  => Proc.new{|*args| after_instance_hook_called  = true}   )
    Dog.new('scooby').bark(10)
    before_instance_hook_called.should == true
    after_instance_hook_called.should  == true
  end

  it "should evaluate singleton instance proc calls" do
    before_singleton_hook_called = false
    after_singleton_hook_called  = false
    scooby = Dog.new('scooby')
    Peep.hook_object!(
            scooby,
            :bark,
            :before => Proc.new{|*args| before_singleton_hook_called = true},
            :after  => Proc.new{|*args| after_singleton_hook_called  = true}   )
    scooby.bark(10)
    before_singleton_hook_called.should == true
    after_singleton_hook_called.should  == true
  end

  it "should evaluate singleton hooks for singleton methods instead of instance methods" do
    scooby = Dog.new('scooby')
    class << scooby
      def eat_scooby_snacks(how_many)
        if how_many > 5
          @mood = :happy
          "Scooby doobee doo!"
        else
          @mood = :hungry
          "I'm hungry, give me more!"
        end
      end
    end

    Peep.hook_object!(
            scooby,
            :eat_scooby_snacks,
            :before => (Proc.new do |object, *params|
              object.instance_variable_get(:@mood).should == nil
              params.should == [10]
            end),
            :after  => (Proc.new do |object, result|
              object.should == scooby
              result.should == "Scooby doobee doo!"
              object.instance_variable_get(:@mood).should == :happy
            end))
    scooby.eat_scooby_snacks(10)
  end

  it "should always override instance method calls with singleton method calls" do
    scooby = Dog.new('scooby')
    lassie = Dog.new('lassie')
    
    Peep.hook_object!(
            scooby,
            :lick_owner,
            :before => Proc.new{|object, *args|   object.owner = "Shaggy" },
            :after  => Proc.new{|object, result|  result.should == "Shaggy is now all wet!" } )
    Peep.hook_instances!(
            Dog,
            :lick_owner,
            :after  => Proc.new{|objetc, result| result.should == "I have no owner to lick :(" } )
    scooby.lick_owner
    lassie.lick_owner
  end

end

describe Peep, "when using parameters in block calls" do

  it_should_behave_like "a clean test"

  it "should accept the same parameters in before hooks as the hooked class methods" do
    Peep.hook_class!(
            Dog,
            :eats?,
            :before => (Proc.new do |klass, *params|
              klass.should == Dog
              params.should == ['meat']
            end))
    Dog.eats?('meat')
  end

  it "should accept the same parameters in before hooks as the hooked instance methods" do
    scooby = Dog.new('scooby')
    Peep.hook_instances!(
    Dog,
    :bark,
    :before => (Proc.new do |object, *params|
              object.should == scooby
              params.should == [3]
            end))
    scooby.bark(3)
  end

  it "should accept the same parameters in before hooks as the hooked singleton method" do
    scooby = Dog.new('scooby')
    Peep.hook_object!(
    scooby,
    :bark,
    :before => (Proc.new do |object, *params|
            params.should == [4]
            object.should == scooby
          end))
    scooby.bark(4)
  end

  it "should return the same object after a hooked class method call" do
    Peep.hook_class!(
            Dog,
            :eats?,
            :after => Proc.new{|klass, result| result.should == true } )
    Dog.eats?('bones')
  end

  it "hould return the same object after a hooked instance method call" do
    scooby = Dog.new('scooby')
    Peep.hook_instances!(
            Dog,
            :bark,
            :after => Proc.new{|klass, result| result.should == "woof woof woof!" } )
    scooby.bark(3)
  end

  it "should return the same object after a hooked singleton method call" do
    scooby = Dog.new('scooby')
    Peep.hook_object!(
            scooby,
            :lick_owner,
            :before =>  Proc.new{|object, *args| object.owner = "John" },
            :after =>   Proc.new{|object, result| result.should == "John is now all wet!" })
    scooby.lick_owner
  end

end

