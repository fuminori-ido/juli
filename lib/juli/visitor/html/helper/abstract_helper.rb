module Juli::Visitor::Html::Helper
  # This is a 'class' for helper method in Html visitor.
  #
  # helper method (e.g. print_user(arg)) is internally worked as follows:
  # 
  # 1. initialize p = PrintUser.new(arg)
  # 1. run p.run on each print_user(arg) calling in html template
  #
  # Currently, each helper must be registered manually.
  class AbstractHelper
    # called when juli(1) starts.
    def initialize
    end

    # called on each parsed document
    def on_root(root)
    end

    # This will be a helper like 'abstract_helper(args)' 
    def run(*args)
    end
  end
end
