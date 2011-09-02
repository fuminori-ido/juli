# import all of visitor/*.rb files

module Juli
  # Namespace for visitors.
  module Visitor
    # since slidy depends on html, order of 'require' is important
    require 'juli/visitor/html'
    require 'juli/visitor/slidy'
    require 'juli/visitor/tree'
  end
end
