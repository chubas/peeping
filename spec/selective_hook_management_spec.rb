require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'peeping')
require File.join(File.dirname(__FILE__), 'helpers', 'test_helpers')

include Peeping

describe Peep, "when adding and removing hooks" do

  it_should_behave_like "a clean test"

  it "should allow to remove class hook methods by method and location" do
    before  = Proc.new{}
    after   = Proc.new{}

    Peep.hook_class!(Dog, [:train, :eats?], :before => before, :after => after)

    hooked_class_methods = Peep.hooked_class_methods_for(Dog)
    hooked_class_methods.should have(2).keys
    hooked_class_methods.should include(:train)
    hooked_class_methods.should include(:eats?)

    hooked_class_methods[:train].should have(2).keys
    hooked_class_methods[:train].should include(:before)
    hooked_class_methods[:train].should include(:after)

    Peep.unhook_class!(Dog, :train, :before)

    hooked_class_methods = Peep.hooked_class_methods_for(Dog)
    hooked_class_methods.should have(2).keys
    hooked_class_methods.keys.should include(:train)
    hooked_class_methods.keys.should include(:eats?)

    hooked_class_methods[:train].should have(1).keys
    hooked_class_methods[:train].should_not include(:before)
    hooked_class_methods[:train].should include(:after)

    Proc.new{ Peep.unhook_class! Dog, :no_such_hook   }.should raise_error UndefinedHookException
    Proc.new{ Peep.unhook_class! Dog, :train, :before }.should raise_error UndefinedHookException

    Peep.unhook_class!(Dog, :train, :after)

    hooked_class_methods = Peep.hooked_class_methods_for(Dog)
    hooked_class_methods.should have(1).keys
    hooked_class_methods.keys.should_not include(:train)
    hooked_class_methods.keys.should include(:eats?)

    Peep.unhook_class!(Dog)

    hooked_class_methods.should have(0).keys
    Peep.is_class_hooked?(Dog).should == false
  end


  it "should allow to remove instance hook methods by method and location" do
    before  = Proc.new{}
    after   = Proc.new{}

    Peep.hook_instances!(Dog, [:bark, :lick_owner], :before => before, :after => after)

    hooked_instance_methods = Peep.hooked_instance_methods_for(Dog)
    hooked_instance_methods.should have(2).keys
    hooked_instance_methods.should include(:bark)
    hooked_instance_methods.should include(:lick_owner)

    hooked_instance_methods[:bark].should have(2).keys
    hooked_instance_methods[:bark].should include(:before)
    hooked_instance_methods[:bark].should include(:after)

    Peep.unhook_instances!(Dog, :bark, :before)

    hooked_instance_methods = Peep.hooked_instance_methods_for(Dog)
    hooked_instance_methods.should have(2).keys
    hooked_instance_methods.keys.should include(:bark)
    hooked_instance_methods.keys.should include(:lick_owner)

    hooked_instance_methods[:bark].should have(1).keys
    hooked_instance_methods[:bark].should_not include(:before)
    hooked_instance_methods[:bark].should include(:after)

    Proc.new{ Peep.unhook_instances! Dog, :no_such_hook   }.should raise_error UndefinedHookException
    Proc.new{ Peep.unhook_instances! Dog, :bark, :before  }.should raise_error UndefinedHookException

    Peep.unhook_instances!(Dog, :bark, :after)

    hooked_instance_methods = Peep.hooked_instance_methods_for(Dog)
    hooked_instance_methods.should have(1).keys
    hooked_instance_methods.keys.should_not include(:bark)
    hooked_instance_methods.keys.should include(:lick_owner)

    Peep.unhook_instances!(Dog)

    hooked_instance_methods.should have(0).keys
  end

  it "should allow to remove singleton hook methods by method and location" do
    before  = Proc.new{}
    after   = Proc.new{}
    scooby  = Dog.new('scooby')

    Peep.hook_object!(scooby, [:bark, :lick_owner], :before => before, :after => after)

    hooked_singleton_methods = Peep.hooked_singleton_methods_for(scooby)
    hooked_singleton_methods.should have(2).keys
    hooked_singleton_methods.should include(:bark)
    hooked_singleton_methods.should include(:lick_owner)

    hooked_singleton_methods[:bark].should have(2).keys
    hooked_singleton_methods[:bark].should include(:before)
    hooked_singleton_methods[:bark].should include(:after)

    Peep.unhook_object!(scooby, :bark, :before)

    hooked_singleton_methods = Peep.hooked_singleton_methods_for(scooby)
    hooked_singleton_methods.should have(2).keys
    hooked_singleton_methods.keys.should include(:bark)
    hooked_singleton_methods.keys.should include(:lick_owner)

    hooked_singleton_methods[:bark].should have(1).keys
    hooked_singleton_methods[:bark].should_not include(:before)
    hooked_singleton_methods[:bark].should include(:after)

    Proc.new{ Peep.unhook_object! scooby, :no_such_hook   }.should raise_error UndefinedHookException
    Proc.new{ Peep.unhook_object! scooby, :bark, :before  }.should raise_error UndefinedHookException

    Peep.unhook_object!(scooby, :bark, :after)

    hooked_singleton_methods = Peep.hooked_singleton_methods_for(scooby)
    hooked_singleton_methods.should have(1).keys
    hooked_singleton_methods.keys.should_not include(:bark)
    hooked_singleton_methods.keys.should include(:lick_owner)

    Peep.unhook_object!(scooby)

    hooked_singleton_methods.should have(0).keys
  end

  it "should keep the instance hook method when removing any singleton hook method" do
    scooby = Dog.new('scooby')
    lassie = Dog.new('lassie')

    before_instance_counter = 0
    after_instance_counter  = 0
    before_object_counter   = 0
    after_object_counter    = 0

    counters_should_be = Proc.new do |bic, aic, boc, aoc|
      before_instance_counter.should  == bic
      after_instance_counter.should   == aic
      before_object_counter.should    == boc
      after_object_counter.should     == aoc
    end

    Peep.hook_instances!(Dog, :lick_owner,
                              :before => Proc.new{ before_instance_counter += 1},
                              :after  => Proc.new{ after_instance_counter  += 1} )
    Peep.hook_object!(scooby, :lick_owner,
                              :before => Proc.new{ before_object_counter   += 1},
                              :after  => Proc.new{ after_object_counter    += 1} )

    scooby.lick_owner
    counters_should_be[0, 0, 1, 1]

    lassie.lick_owner
    counters_should_be[1, 1, 1, 1]

    Peep.unhook_object!(scooby, :lick_owner, :before)
    scooby.lick_owner
    counters_should_be[2, 1, 1, 2]
    lassie.lick_owner
    counters_should_be[3, 2, 1, 2]

    Peep.unhook_instances!(Dog, :lick_owner, :after)
    scooby.lick_owner
    counters_should_be[4, 2, 1, 3]
    lassie.lick_owner
    counters_should_be[5, 2, 1, 3]

    Peep.unhook_object!(scooby, :lick_owner, :after)
    scooby.lick_owner
    counters_should_be[6, 2, 1, 3]
    lassie.lick_owner
    counters_should_be[7, 2, 1, 3]

    Peep.unhook_instances!(Dog, :lick_owner)
    scooby.lick_owner
    lassie.lick_owner
    counters_should_be[7, 2, 1, 3]
  end

end