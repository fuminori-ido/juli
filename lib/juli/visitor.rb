# import all of visitor/*.rb files

module Juli
  # Namespace for visitors.
  module Visitor
    Dir.glob(File.join(File.dirname(__FILE__), 'visitor/*.rb')){|v|
      require File.join('juli/visitor', File.basename(v))
    }
  end
end
