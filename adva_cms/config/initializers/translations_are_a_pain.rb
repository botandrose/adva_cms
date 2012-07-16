module I18n
  class MissingTranslation
    module Base
      def message
        key.to_s.capitalize
      end
    end
  end
end
