require 'rack'
require 'prometheus/client/rack/collector'
require 'prometheus/client/rack/exporter'

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }
use Prometheus::Client::Rack::Collector, prefork: true
use Prometheus::Client::Rack::Exporter, prefork: true
run ->(_) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
