require "belongs_to_cacheable"

module Adva
  module BelongsToAuthor
    def self.included(base)
      base.include BelongsToCacheable
      base.extend ClassMethods
    end

    module ClassMethods
      def belongs_to_user(*args)
        options = args.extract_options!
        args = (args.empty? ? [:user] : args)
        belongs_to_cacheable *args.dup << options # FIXME should not be polymorphic!
        
        args.each do |name|
          class_eval <<-code, __FILE__, __LINE__
            def #{name}_ip
              #{name}.ip if #{name} && #{name}.respond_to?(:ip)
            end

            def #{name}_agent
              #{name}.agent if #{name} && #{name}.respond_to?(:agent)
            end

            def #{name}_referer
              #{name}.referer if #{name} && #{name}.respond_to?(:referer)
            end

            def #{name}_link include_email: true
              if include_email
                %(<a href="mailto:\#{#{name}_email}">\#{#{name}_name}</a>).html_safe
              else
                #{name}_name
              end
            end
          code
        end
      end

      def belongs_to_author(*args)
        options = args.extract_options!
        args = (args.empty? ? [:author] : args) << options
        belongs_to_user *args
      end
    end
  end
end
