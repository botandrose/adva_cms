module CacheableFlash
  class Middleware
    def initialize app
      @app = app
    end

    def call env
      status, headers, body = @app.call env
      return [status, headers, body] unless headers["Content-Type"].try(:include?, "text/html")

      new_body = ""
      body.each { |part| new_body << part }
      process! new_body
      headers.delete("Content-Length")

      [status, headers, [new_body]]
    end

    private

    def process! body
      body.gsub!("</head>", "<script>#{javascript}</script></head>")
    end

    def javascript
      File.read(__dir__ + "/javascript.js")
    end
  end
end

