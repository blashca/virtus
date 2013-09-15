module Virtus

  # A set of Attribute objects
  class AttributeSet < Module
    include Enumerable

    # Initialize an AttributeSet
    #
    # @param [AttributeSet] parent
    # @param [Array] attributes
    #
    # @return [undefined]
    #
    # @api private
    def initialize(parent = nil, attributes = [])
      @parent     = parent
      @attributes = attributes.dup
      @index      = {}
      reset
    end

    # Iterate over each attribute in the set
    #
    # @example
    #   attribute_set = AttributeSet.new(attributes, parent)
    #   attribute_set.each { |attribute| ... }
    #
    # @yield [attribute]
    #
    # @yieldparam [Attribute] attribute
    #   each attribute in the set
    #
    # @return [self]
    #
    # @api public
    def each
      return to_enum unless block_given?
      @index.values.uniq.each { |attribute| yield attribute }
      self
    end

    # Adds the attributes to the set
    #
    # @example
    #   attribute_set.merge(attributes)
    #
    # @param [Array<Attribute>] attributes
    #
    # @return [self]
    #
    # @api public
    def merge(attributes)
      attributes.each { |attribute| self << attribute }
      self
    end

    # Adds an attribute to the set
    #
    # @example
    #   attribute_set << attribute
    #
    # @param [Attribute] attribute
    #
    # @return [self]
    #
    # @api public
    def <<(attribute)
      self[attribute.name] = attribute
      attribute.define_accessor_methods(self)
      self
    end

    # Get an attribute by name
    #
    # @example
    #   attribute_set[:name]  # => Attribute object
    #
    # @param [Symbol] name
    #
    # @return [Attribute]
    #
    # @api public
    def [](name)
      @index[name]
    end

    # Set an attribute by name
    #
    # @example
    #   attribute_set[:name] = attribute
    #
    # @param [Symbol] name
    # @param [Attribute] attribute
    #
    # @return [Attribute]
    #
    # @api public
    def []=(name, attribute)
      @attributes << attribute
      update_index(name, attribute)
    end

    # Reset the index when the parent is updated
    #
    # @return [self]
    #
    # @api private
    def reset
      merge_attributes(@parent) if @parent
      merge_attributes(@attributes)
      self
    end

    # Defines an attribute reader method
    #
    # @param [Attribute] attribute
    # @param [Symbol] method_name
    # @param [Symbol] visibility
    #
    # @return [self]
    #
    # @api private
    def define_reader_method(attribute, method_name, visibility)
      define_method(method_name) { attribute.get(self) }
      send(visibility, method_name)
      self
    end

    # Defines an attribute writer method
    #
    # @param [Attribute] attribute
    # @param [Symbol] method_name
    # @param [Symbol] visibility
    #
    # @return [self]
    #
    # @api private
    def define_writer_method(attribute, method_name, visibility)
      define_method(method_name) { |value| attribute.set(self, value) }
      send(visibility, method_name)
      self
    end

    # Get values of all attributes defined for this class, ignoring privacy
    #
    # @return [Hash]
    #
    # @api private
    def get(object, &block)
      each_with_object({}) do |attribute, attributes|
        name = attribute.name
        attributes[name] = object.__send__(name) if yield(attribute)
      end
    end

    # Mass-assign attribute values
    #
    # @see Virtus::InstanceMethods#attributes=
    #
    # @return [Hash]
    #
    # @api private
    def set(object, attributes)
      coerce(attributes).each do |name, value|
        writer_name = "#{name}="
        if object.allowed_writer_methods.include?(writer_name)
          object.__send__(writer_name, value)
        end
      end
    end

    # Set default attributes
    #
    # @return [self]
    #
    # @api private
    def set_defaults(object)
      each do |attribute|
        if object.instance_variable_defined?(attribute.instance_variable_name) || attribute.lazy?
          next
        end
        attribute.set_default_value(object)
      end
    end

    # Coerce attributes received to a hash
    #
    # @return [Hash]
    #
    # @api private
    def coerce(attributes)
      ::Hash.try_convert(attributes) or raise(
        NoMethodError, "Expected #{attributes.inspect} to respond to #to_hash"
      )
    end

  private

    # Merge the attributes into the index
    #
    # @param [Array<Attribute>] attributes
    #
    # @return [undefined]
    #
    # @api private
    def merge_attributes(attributes)
      attributes.each { |attribute| update_index(attribute.name, attribute) }
    end

    # Update the symbol and string indexes with the attribute
    #
    # @param [Symbol] name
    #
    # @param [Attribute] attribute
    #
    # @return [undefined]
    #
    # @api private
    def update_index(name, attribute)
      @index[name] = @index[name.to_s.freeze] = attribute
    end

  end # class AttributeSet
end # module Virtus
