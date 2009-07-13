require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'peeping')
require File.join(File.dirname(__FILE__), 'helpers', 'test_helpers')


include Peeping

describe Peep, "determining if objects are hooked, and get hooks for class or object" do

  it_should_behave_like "a clean test"

  it "should allow me to determine wether a class is hooked" do
    include Peeping
    Peep.should respond_to(:is_class_hooked?)
    Peep.should respond_to(:hooked_class_methods_for)
  end

  it "should allow me to determine if all instances of a class are hooked" do
    Peep.should respond_to(:are_instances_hooked?)
    Peep.should respond_to(:hooked_instance_methods_for)
  end

  it "should allow me to determine if a single object is hooked" do
    Peep.should respond_to(:is_hooked?)
    Peep.should respond_to(:hooked_singleton_methods_for)
  end

end

describe Peep, "when hooking and unhooking objects" do

  it_should_behave_like "a clean test"

  it "should allow to me to hook and unhook classes" do
    Peep.is_class_hooked?(Dog).should == false
    Peep.hooked_class_methods_for(Dog).should be_empty

    after_call = Proc.new{|klass, result| result}
    Peep.hook_class!(Dog, :train, :after => after_call)

    Peep.is_class_hooked?(Dog).should == true
    Peep.hooked_class_methods_for(Dog).should_not be_empty
    Peep.hooked_class_methods_for(Dog).should have(1).keys
    Peep.hooked_class_methods_for(Dog)[:train][:after].should == after_call

    Peep.unhook_class!(Dog)

    Peep.is_class_hooked?(Dog).should == false
    Peep.hooked_class_methods_for(Dog).should be_empty
  end

  it "should allow me to hook and unhook instance methods" do
    Peep.are_instances_hooked?(Dog).should == false
    Peep.hooked_instance_methods_for(Dog).should be_empty

    after_call = Proc.new{|klass, result| result}
    Peep.hook_instances!(Dog, :bark, :after => after_call)

    Peep.are_instances_hooked?(Dog).should == true
    Peep.hooked_instance_methods_for(Dog).should_not be_empty
    Peep.hooked_instance_methods_for(Dog).should have(1).keys
    Peep.hooked_instance_methods_for(Dog)[:bark][:after].should == after_call

    Peep.unhook_instances!(Dog)

    Peep.are_instances_hooked?(Dog).should == false
    Peep.hooked_instance_methods_for(Dog).should be_empty
  end

  it "should allow me to hook and unhook single objects" do
    scooby = Dog.new("scooby")
    Peep.is_hooked?(scooby).should == false

    after_call = Proc.new{|klass, result| result}
    Peep.hook_object!(scooby, :bark, :after => after_call)

    Peep.is_hooked?(scooby).should == true
    Peep.hooked_singleton_methods_for(scooby).should_not be_empty
    Peep.hooked_singleton_methods_for(scooby).should have(1).keys
    Peep.hooked_singleton_methods_for(scooby)[:bark][:after].should == after_call

    Peep.are_instances_hooked?(Dog).should == false
    Peep.hooked_instance_methods_for(Dog).should be_empty

    Peep.unhook_object!(scooby)

    Peep.is_hooked?(scooby).should == false
    Peep.hooked_singleton_methods_for(scooby).should be_empty
  end
end

describe Peep, "when sending valid and unvalid parameters" do

  it_should_behave_like "a clean test"

  it "should only accept valid parameters for hooks" do
    scooby        = Dog.new("scooby")
    invalid_keys  = { :invalid => :key }

    Proc.new{ Peep.hook_class! Dog, :hello, invalid_keys }.should raise_error InvalidHooksException
    Proc.new{ Peep.hook_class! Dog, :hello, {}           }.should raise_error InvalidHooksException

    Proc.new{ Peep.hook_instances! Dog, :hello, invalid_keys }.should raise_error InvalidHooksException
    Proc.new{ Peep.hook_instances! Dog, :hello, {}           }.should raise_error InvalidHooksException

    Proc.new{ Peep.hook_object! scooby, :hello, invalid_keys }.should raise_error InvalidHooksException
    Proc.new{ Peep.hook_object! scooby, :hello, {}           }.should raise_error InvalidHooksException
  end

  it "should validate that methods are defined" do
    p = Proc.new{|klass, result| result }
    scooby = Dog.new("scooby")

    Proc.new{ Peep.hook_class! Dog, :dance, :after => p     }.should raise_error UndefinedMethodException
    Proc.new{ Peep.hook_instances! Dog, :dance, :after => p }.should raise_error UndefinedMethodException
    Proc.new{ Peep.hook_object! scooby, :dance, :after => p }.should raise_error UndefinedMethodException
  end

  it "should validate that passed objects are classes for class and instance hooks" do
    p = Proc.new{|klass, result| result}
    Proc.new{ Peep.hook_class! :not_a_class, :hello, :after => p      }.should raise_error NotAClassException
    Proc.new{ Peep.hook_instances! :not_a_class, :hello, :after => p  }.should raise_error NotAClassException
  end

  it "should rise an error if a hook is declared twice" do
    p = Proc.new{|klass, result| result}
    Peep.hook_class! Dog, :train, :after => p
    Proc.new{ Peep.hook_class! Dog, :train, :after => p     }.should raise_error AlreadyDefinedHookException

    Peep.hook_instances! Dog, :bark, :after => p
    Proc.new{ Peep.hook_instances! Dog, :bark, :after => p  }.should raise_error AlreadyDefinedHookException

    scooby = Dog.new("scooby")
    Peep.hook_object! scooby, :bark, :after => p
    Proc.new{ Peep.hook_object! scooby, :bark, :after => p  }.should raise_error AlreadyDefinedHookException
  end

end

