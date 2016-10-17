# encoding: UTF-8

require 'thread'
require 'prometheus/client/label_set_validator'
require 'prometheus/client/stores/hash'
require 'prometheus/client/stores/pstore'

module Prometheus
  module Client
    # Metric
    class Metric
      attr_reader :name, :docstring, :base_labels

      def initialize(name, docstring, base_labels = {}, store_class = Stores::Hash)
        @validator = LabelSetValidator.new

        validate_name(name)
        validate_docstring(docstring)
        @validator.valid?(base_labels)

        @name = name
        @docstring = docstring
        @base_labels = base_labels

        @store = store_class.new(self)
      end

      # Returns the value for the given label set
      def get(labels = {})
        @validator.valid?(labels)

        @store.get(labels)
      end

      # Returns all label sets with their values
      def values
        @store.values
      end

      def default
        nil
      end

      private

      def validate_name(name)
        return true if name.is_a?(Symbol)

        raise ArgumentError, 'given name must be a symbol'
      end

      def validate_docstring(docstring)
        return true if docstring.respond_to?(:empty?) && !docstring.empty?

        raise ArgumentError, 'docstring must be given'
      end

      def label_set_for(labels)
        @validator.validate(labels)
      end
    end
  end
end
