ActionController::Base.class_eval do
  prepend Module.new {
    def url_for(options = {})
      return super(options) unless options.is_a?(Hash)

      case returning = options.delete(:return)
      when true, :here
        options.reverse_merge! :return_to => params[:return_to] || request.request_uri
      end
      super(options)
    end
  }
end
