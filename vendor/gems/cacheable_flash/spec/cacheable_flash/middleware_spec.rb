# frozen_string_literal: true

require "cacheable_flash/middleware"

RSpec.describe CacheableFlash::Middleware do
  # ActiveSupport adds Object#try, which the middleware uses. For tests, we can
  # emulate that behavior by subclassing String to provide #try.
  class TryString < String
    def try(method_name, *args)
      public_send(method_name, *args)
    end
  end

  let(:html) { "<html><head></head><body>Hello</body></html>" }

  it "injects the javascript into HTML responses" do
    app = ->(_env) { [200, { "Content-Type" => TryString.new("text/html; charset=utf-8") }, [html]] }
    middleware = described_class.new(app)

    status, headers, body = middleware.call({})

    expect(status).to eq(200)
    expect(headers).not_to have_key("Content-Length")

    aggregated = String.new
    body.each { |part| aggregated << part }

    expect(aggregated).to include("</head>")
    expect(aggregated).to match(%r{<script>.*</script></head>}m)
    # Ensure it actually read our embedded JS file content by checking a known token
    expect(aggregated).to include("document.addEventListener(")
  end

  it "passes through non-HTML responses unchanged" do
    app = ->(_env) { [201, { "Content-Type" => TryString.new("application/json") }, ["{}"]] }
    middleware = described_class.new(app)

    status, headers, body = middleware.call({})
    aggregated = String.new
    body.each { |part| aggregated << part }

    expect(status).to eq(201)
    expect(aggregated).to eq("{}")
  end
end
