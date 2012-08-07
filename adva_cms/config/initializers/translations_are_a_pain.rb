module I18n
  class MissingTranslation
    module Base
      def message
        key.to_s.titleize
      end
    end
  end
end
