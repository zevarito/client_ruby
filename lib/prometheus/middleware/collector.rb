# encoding: UTF-8

require 'prometheus/client'

module Prometheus
  module Middleware
    # Collector is a Rack middleware that provides a sample implementation of
    # a HTTP tracer. The default label builder can be modified to export a
    # different set of labels per recorded metric.
    class Collector
      attr_reader :app, :registry

      def initialize(app, options = {}, &label_builder)
        @app = app
        @registry = options[:registry] || Client.registry
        @label_builder = label_builder || DEFAULT_LABEL_BUILDER

        init_request_metrics
        init_exception_metrics
      end

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      DEFAULT_LABEL_BUILDER = proc do |env|
        {
          method: env['REQUEST_METHOD'].downcase,
          path:   env['PATH_INFO'].to_s,
        }
      end

      def init_request_metrics
        @requests = @registry.counter(
          :http_server_requests_total,
          'The total number of HTTP requests handled by the Rack application.',
        )
        @durations = @registry.histogram(
          :http_server_request_latency_seconds,
          'The HTTP response latency of the Rack application.',
        )
      end

      def init_exception_metrics
        @exceptions = @registry.counter(
          :http_server_exceptions_total,
          'The total number of exceptions raised by the Rack application.',
        )
      end

      def trace(env)
        start = Time.now
        yield.tap do |response|
          duration = (Time.now - start).to_f
          record(labels(env, response), duration)
        end
      rescue => exception
        @exceptions.increment(exception: exception.class.name)
        raise
      end

      def labels(env, response)
        @label_builder.call(env).tap do |labels|
          labels[:code] = response.first.to_s
        end
      end

      def record(labels, duration)
        @requests.increment(labels)
        @durations.observe(labels, duration)
      rescue
        # TODO: log unexpected exception during request recording
        nil
      end
    end
  end
end
