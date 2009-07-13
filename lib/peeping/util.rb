#--
# Utility methods

class Object

  # In case it has not been defined before 
  def metaclass
    class << self
      self
    end
  end unless method_defined?(:metaclass)
end
#++