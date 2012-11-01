module Rlint
  module Analyze
    ##
    # {Rlint::Analyze::Definitions} is a callback class that is used for
    # building a list of all the definitions (variables, methods, etc) of a
    # block of Ruby code.
    #
    # The resulting instance of {Rlint::Scope} is stored in the `@storage`
    # instance variable under the key `:scope`. This makes it possible for
    # other callback classes to access this data easily.
    #
    class Definitions < Rlint::Callback
      ##
      # Array containing the key names of the variables that should be exported
      # out of a method definition.
      #
      # @return [Array]
      #
      EXPORT_VARIABLES = [:instance_variable, :class_variable, :constant]

      ##
      # @see Rlint::Callback#initialize
      #
      def initialize(*args)
        super

        @storage[:scope] = Scope.new(nil, true, true)
        @scopes          = []
        @namespace       = []
      end

      ##
      # Called when a value is assigned to a variable.
      #
      # @param [Rlint::Token::AssignmentToken] token
      #
      def on_assignment(token)
        if token.type == :global_variable
          variable_scope = @storage[:scope]
        else
          variable_scope = scope
        end

        # Assignment using a constant path. In this case each path segment
        # should exist (with the exception of the last one) for the assignment
        # to take place.
        if token.name.is_a?(Array)
          name_scope = scope

          token.name[0..-2].each do |segment|
            name_scope = name_scope.lookup(:constant, segment)
          end

          if name_scope
            variable_scope = name_scope
          else
            on_constant_path(token)

            return
          end

          name = token.name[-1]
          type = :constant
        else
          name = token.name
          type = token.type
        end

        variable_scope.add(type, name, Definition.new(token, nil, false))
      end

      ##
      # Called when a new method is defined.
      #
      # @param [Rlint::Token::MethodDefinitionToken] token
      #
      def on_method_definition(token)
        type      = :instance_method
        new_scope = Scope.new(scope)
        target    = scope

        token.parameters.each do |param|
          new_scope.add(
            param.type,
            param.name,
            Definition.new(param, nil, false)
          )
        end

        # The method is a class method.
        if token.receiver
          type = :method

          if token.receiver.name != 'self' \
          and token.receiver.name != @namespace[-1]
            found  = target.lookup(token.receiver.type, token.receiver.name)
            target = found if found
          end
        end

        target.add(type, token.name, Definition.new(token, new_scope))

        @scopes << new_scope
      end

      ##
      # Called after a method definition has been processed.
      #
      # @see Rlint::Analyze::Definitions#on_method_definition
      #
      def after_method_definition(token)
        # TODO: exporting these variables should only be done if the method is
        # actually called.
        last_scope = @scopes.pop

        EXPORT_VARIABLES.each do |key|
          scope.symbols[key] = scope.symbols[key].merge(
            last_scope.symbols[key]
          )
        end
      end

      ##
      # Called when a class definition is found.
      #
      # @param [Rlint::Token::ClassToken] token
      #
      def on_class(token)
        name       = token.name.join('::')
        @namespace << name

        # If a class has already been defined the scoping data should not be
        # overwritten.
        return if scope.lookup(:constant, name)

        parent    = scope.lookup(:constant, token.parent.join('::'))
        parent    = parent.scope if parent.respond_to?(:scope)
        new_scope = Scope.new([parent, scope])

        scope.add(:constant, name, Definition.new(token, new_scope))

        @scopes << new_scope
      end

      ##
      # Called after a class definition was found and processed.
      #
      # @see Rlint::Analyze::Definitions#on_class
      #
      def after_class(token)
        @scopes.pop
        @namespace.pop
      end

      ##
      # Called when a module is defined.
      #
      # @param [Rlint::Token::Token] token
      #
      def on_module(token)
        name       = token.name.join('::')
        @namespace << name

        # If a module has already been defined the scope should not be
        # overwritten.
        return if scope.lookup(:constant, name)

        new_scope = Scope.new(scope)

        scope.add(:constant, name, Definition.new(token, new_scope))

        @scopes << new_scope
      end

      ##
      # Called after a module definition has been processed.
      #
      # @see Rlint::Analyze::Definitions#on_module
      #
      def after_module(token)
        @scopes.pop
        @namespace.pop
      end

      private

      ##
      # Returns the current scope. This method is primarily used to make the
      # code in this class a bit more pleasant to read.
      #
      # @return [Rlint::Scope]
      #
      def scope
        return !@scopes.empty? ? @scopes[-1] : @storage[:scope]
      end
    end # Definitions
  end # Analyze
end # Rlint
