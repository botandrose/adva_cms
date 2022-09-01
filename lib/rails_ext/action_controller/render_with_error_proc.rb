ActionController::Base.class_eval do
  class_attribute :default_error_proc

  class << self
    def renders_with_error_proc(error_proc_key)
      self.default_error_proc = error_proc_key
    end
  end

  cattr_accessor :field_error_procs
  self.field_error_procs = {
    :above_field => Proc.new { |html_tag, instance|
      html_tag =~ /<label/ ? html_tag : %(<span class="error_message">#{Array(instance.error_message).to_sentence}</span>).html_safe + html_tag
    },
    :below_field => Proc.new { |html_tag, instance|
      html_tag =~ /<label/ ? html_tag : html_tag + %(<span class="error_message">#{Array(instance.error_message).to_sentence}</span>).html_safe
    }
  }
  
  prepend Module.new {
    def render(*args, &block)
      options = args.last.is_a?(Hash) ? args.last : {}
      with_error_proc(extract_error_proc_key(options)) do
        super(*args, &block)
      end
    end
  }

  def extract_error_proc_key(options)
    error_proc_key = options.delete(:errors) if options.is_a? Hash
    error_proc_key ||= self.class.default_error_proc
  end

  def with_error_proc(error_proc_key)
    if error_proc_key
      raise "invalid error_proc_key: #{error_proc_key}" unless self.field_error_procs[error_proc_key]
      old_proc = ActionView::Base.field_error_proc
      ActionView::Base.field_error_proc = self.field_error_procs[error_proc_key]
      yield.tap do
        ActionView::Base.field_error_proc = old_proc
      end
    else
      yield
    end
  end
  helper_method :with_error_proc
end
