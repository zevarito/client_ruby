# encoding: UTF-8

require 'thread'
require 'prometheus/client/label_set_validator'

module Prometheus
  module Client
    # Metric
    class Metric
      attr_reader :name, :docstring, :base_labels

      def initialize(name, docstring, base_labels = {})
        @mutex = Mutex.new
        @tempfile = Tempfile.new(["prometheus-#{Process.pid}-#{name}",'.pstore'])
        @store = PStore.new(@tempfile.path)
        @validator = LabelSetValidator.new

        validate_name(name)
        validate_docstring(docstring)
        @validator.valid?(base_labels)

        @name = name
        @docstring = docstring
        @base_labels = base_labels
      end

      # Returns the metric type
      def type
        fail NotImplementedError
      end

      # Returns the value for the given label set
      def get(labels = {})
        @validator.valid?(labels)

        @store[labels]
      end

      # Returns all label sets with their values
      def values
        synchronize do
          @store.transaction do
            return unless @store.roots
            @store.roots.each_with_object({}) do |label, memo|
              memo[label] = @store[label]
            end
          end
        end
      end

      private

      def default
        nil
      end

      def validate_name(name)
        return true if name.is_a?(Symbol)

        fail ArgumentError, 'given name must be a symbol'
      end

      def validate_docstring(docstring)
        return true if docstring.respond_to?(:empty?) && !docstring.empty?

        fail ArgumentError, 'docstring must be given'
      end

      def label_set_for(labels)
        @validator.validate(labels)
      end

      def synchronize(&block)
        @mutex.synchronize(&block)
      end
    end
  end
end
