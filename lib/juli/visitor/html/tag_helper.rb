class Juli::Visitor::Html
    # copied from Rails
    module TagHelper
      def tag(name, options = nil, open = false)
        "<#{name}#{tag_options(options) if options}#{open ? ">" : " />"}"
      end
    
      def content_tag(name, content_or_options_with_block = nil, options = nil, &block)
        if block_given?
          options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
          content_tag_string(name, block.call, options)
        else
          content_tag_string(name, content_or_options_with_block, options)
        end
      end
    
    private
      BOOLEAN_ATTRIBUTES = %w(disabled readonly multiple checked)
      BOOLEAN_ATTRIBUTES << BOOLEAN_ATTRIBUTES.map(&:to_sym)
    
      def content_tag_string(name, content, options)
        tag_options = tag_options(options) if options
        "<#{name}#{tag_options}>#{content}</#{name}>"
      end
    
      def tag_options(options)
        if options != {}
          attrs = []
          options.each_pair do |key, value|
            if BOOLEAN_ATTRIBUTES.include?(key)
              attrs << key if value
            else
              attrs << %(#{key}="#{value}") if !value.nil?
            end
          end
          " #{attrs.sort * ' '}" unless attrs.empty?
        end
      end
    end
end
