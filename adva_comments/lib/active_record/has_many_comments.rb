module ActiveRecord
  module HasManyComments
    def self.included(base)
      base.extend ActMacro
    end

    module ActMacro
      def has_many_comments(options = {})
        return if has_many_comments?

        order_options = options.delete(:order) || [:created_at, :id]
        options[:class_name] ||= 'Comment'

        has_counter :comments,
                    :as => options[:as]

        has_counter :approved_comments,
                    :as => options[:as],
                    :class_name => 'Comment',
                    :callbacks => { 
                      :after_approve   => :increment!, 
                      :after_unapprove => :decrement!, 
                      :after_destroy  => lambda { |record| :decrement! if record.approved? }
                    }

        options.delete(:as) unless options[:as] == :commentable
        with_options options do |c|
          c.has_many :comments, -> { order(order_options) }, dependent: :delete_all do
            def by_author(author)
              find_all_by_author_id_and_author_type(author.id, author.class.name)
            end
          end
          c.has_many :approved_comments,   -> { where(["comments.approved = ?", 1]).order(order_options) }
          c.has_many :unapproved_comments, -> { where(["comments.approved = ?", 0]).order(order_options) }
        end

        include InstanceMethods
      end

      def has_many_comments?
        included_modules.include? ActiveRecord::HasManyComments::InstanceMethods
      end
    end

    module InstanceMethods
    end
  end
end
ActiveRecord::Base.send :include, ActiveRecord::HasManyComments
