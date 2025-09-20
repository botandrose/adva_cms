RSpec.configure do |config|
  # On request spec failures (500s), print a snippet of the response body
  config.after(type: :request) do |example|
    begin
      if respond_to?(:response) && response && response.status.to_i >= 500
        ex = nil
        if respond_to?(:request) && request && request.respond_to?(:env)
          ex = request.env["action_dispatch.exception"]
        end
        if ex
          warn "\n*** EXCEPTION: #{ex.class}: #{ex.message}\n"
        end
        snippet = response.body.to_s.split("\n").first(120).join("\n")
        warn "\n----- RESPONSE BODY (#{response.status}) -----\n#{snippet}\n----------------------------------------------\n"
      end
    rescue => e
      warn "(failed to dump response body: #{e.class}: #{e.message})"
    end
  end
end
