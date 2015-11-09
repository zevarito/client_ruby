$LOAD_PATH << File.expand_path('../../lib', File.dirname(__FILE__))

require 'rack'
require 'prometheus/client/rack/collector'
require 'prometheus/client/rack/exporter'

use Prometheus::Client::Rack::Collector, prefork: true
use Prometheus::Client::Rack::Exporter, prefork: true
run ->(_) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
