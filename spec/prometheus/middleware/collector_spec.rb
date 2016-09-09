# encoding: UTF-8

require 'rack/test'
require 'prometheus/middleware/collector'

describe Prometheus::Middleware::Collector do
  include Rack::Test::Methods

  let(:registry) do
    Prometheus::Client::Registry.new
  end

  let(:original_app) do
    ->(_) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
  end

  let!(:app) do
    described_class.new(original_app, registry: registry)
  end

  it 'returns the app response' do
    get '/foo'

    expect(last_response).to be_ok
    expect(last_response.body).to eql('OK')
  end

  it 'handles errors in the registry gracefully' do
    counter = registry.get(:http_server_requests_total)
    expect(counter).to receive(:increment).and_raise(NoMethodError)

    get '/foo'

    expect(last_response).to be_ok
  end

  it 'traces request information' do
    expect(Time).to receive(:now).twice.and_return(0.0, 0.2)
    labels = { method: 'get', path: '/foo', code: '200' }

    get '/foo'

    {
      http_server_requests_total: eql(1),
      http_server_request_latency_seconds: include(0.1 => 0, 0.25 => 1),
    }.each do |metric, expectation|
      expect(registry.get(metric).get(labels)).to expectation
    end
  end

  context 'when the app raises an exception' do
    let(:original_app) do
      lambda do |env|
        raise NoMethodError if env['PATH_INFO'] == '/broken'

        [200, { 'Content-Type' => 'text/html' }, ['OK']]
      end
    end

    before do
      get '/foo'
    end

    it 'traces exceptions' do
      labels = { exception: 'NoMethodError' }

      expect { get '/broken' }.to raise_error NoMethodError

      expect(registry.get(:http_server_exceptions_total).get(labels)).to eql(1)
    end
  end

  context 'setting up with a block' do
    let(:app) do
      described_class.new(original_app, registry: registry) do |env|
        { method: env['REQUEST_METHOD'].downcase } # and ignore the path
      end
    end

    it 'allows labels configuration' do
      get '/foo/bar'

      labels = { method: 'get', code: '200' }

      expect(registry.get(:http_server_requests_total).get(labels)).to eql(1)
    end
  end
end
