# encoding: UTF-8

require 'prometheus/client/registry'

module Prometheus
  # Client is a ruby implementation for a Prometheus compatible client.
  module Client
    # Returns a default registry object
    def self.registry(store_class)
      @registry ||= Registry.new(store_class)
    end
  end
end
