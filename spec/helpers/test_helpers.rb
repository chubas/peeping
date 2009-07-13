require 'spec'

shared_examples_for 'a clean test' do
  before{ Peeping::Peep.clear_all_hooks! }
  after { Peeping::Peep.clear_all_hooks! }
end

#--
# Dummy class, used for testing
class Dog

  attr_accessor :name, :trained, :owner
  attr_accessor :a, :b

  def initialize(name)
    @name = name
  end

  def bark(times)
    (["woof"] * times).join(' ') + "!"
  end

  def lick_owner
    if @owner
      "#{@owner} is now all wet!"
    else
      "I have no owner to lick :("
    end
  end

  def self.train(dog)
    dog.trained = true
    dog
  end

  def self.eats?(thing)
    %w{meat bones milk}.include?(thing)
  end

end
#++

