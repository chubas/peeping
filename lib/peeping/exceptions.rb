module Peeping
  class InvalidHooksException       < Exception; end
  class UndefinedMethodException    < Exception; end
  class NotAClassException          < Exception; end
  class AlreadyDefinedHookException < Exception; end
  class UndefinedHookException      < Exception; end
end