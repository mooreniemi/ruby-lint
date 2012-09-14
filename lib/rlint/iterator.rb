module Rlint
  ##
  # {Rlint::Iterator} is a class that iterates over the AST nodes of
  # {Rlint::Parser} and executes any bound callbacks for the various node types
  # it finds.
  #
  class Iterator
    ##
    # Array containing a set of instance specific callback objects.
    #
    # @return [Array]
    #
    attr_reader :callbacks

    def initialize(report = nil)
      @callbacks = []
      @report    = report
    end

    def iterate(nodes)
      nodes.each do |node|
        next unless node.is_a?(Rlint::Token::Token)

        event_name     = node.event.to_s
        callback_name  = 'on_' + event_name
        after_callback = 'after_' + event_name

        @callbacks.each do |obj|
          if obj.respond_to?(callback_name)
            obj.send(callback_name, node)
          end
        end

        # Iterate over all the child nodes.
        if node.value and node.value.respond_to?(:each)
          iterate(node.value)
        end

        # Loop through method parameters.
        if node.respond_to?(:parameters) \
        and node.parameters.respond_to?(:each)
          iterate(node.parameters)
        end

        @callbacks.each do |obj|
          if obj.respond_to?(after_callback)
            obj.send(after_callback, node)
          end
        end
      end
    end

    def bind(callback_class)
      @callbacks << callback_class.new(@report)
    end
  end # Iterator
end # Rlint