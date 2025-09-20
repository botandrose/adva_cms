class ApplicationController < ActionController::Base
  if Rails.env.test?
    rescue_from StandardError do |ex|
      body = "#{ex.class}: #{ex.message}\n\n" + Array(ex.backtrace).first(20).join("\n")
      render plain: body, status: 500
    end
  end
end
