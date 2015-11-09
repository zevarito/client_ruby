# encoding: UTF-8

require 'prometheus/client/store'
require 'pstore'

module Prometheus
  module Client
    module Stores
      class PStore < Store
        def initialize(metric)
          @mutex = Mutex.new
          @metric = metric

          @tempfile = Tempfile.new(["prometheus-#{Process.pid}-#{metric.name}", '.pstore'])
          @values = ::PStore.new(@tempfile.path)
        end

        def synchronize(&block)
          @values.transaction do
            @mutex.synchronize(&block)
          end
        end

        def values
          synchronize do
            return [] unless @values.roots
            @values.roots.each_with_object({}) do |labels, memo|
              memo[labels] = @values[labels]
            end
          end
        end
      end
    end
  end
end
