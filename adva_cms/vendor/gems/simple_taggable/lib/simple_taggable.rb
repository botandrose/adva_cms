require "simple_taggable/version"

require 'tag_list'
require 'tag'
require 'tagging'

module SimpleTaggable
end

module ActiveRecord
  module Acts
    module Taggable
      module ActMacro
        def acts_as_taggable(options = {})
          return if acts_as_taggable?

          include ActiveRecord::Acts::Taggable::InstanceMethods
          extend ActiveRecord::Acts::Taggable::ClassMethods

          has_many :taggings, -> { includes(:tag) }, as: :taggable, dependent: :destroy
          has_many :tags, :through => :taggings

          before_save :cache_tag_list
          after_save :save_tags

          prepend Module.new {
            def reload(*)
              @tag_list = nil
              super
            end
          }
        end

        def acts_as_taggable?
          included_modules.include?(ActiveRecord::Acts::Taggable::InstanceMethods)
        end
      end

      module ClassMethods
        def tag_counts(*args)
          options = args.extract_options!
          options.assert_valid_keys :conditions, :at_least, :at_most, :order, :limit

          conditions = ["taggings.taggable_type = '#{base_class.name}'"]
          conditions << options.delete(:conditions) if options[:conditions]
          conditions << type_condition unless descends_from_active_record?

          joins = []
          joins << "INNER JOIN taggings ON tags.id = taggings.tag_id"
          joins << "INNER JOIN #{table_name} ON #{table_name}.id = taggings.taggable_id"

          at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options.key?(:at_least)
          at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options.key?(:at_most)
          having    = [at_least, at_most].compact.join(' AND ')

          group_by  = "tags.id, tags.name HAVING count(*) > 0"
          group_by << " AND #{having}" unless having.blank?

          options.merge! :select     => "tags.*, COUNT(*) AS count",
                         :conditions => conditions.compact.join(' AND '),
                         :joins      => joins.compact.join(' '),
                         :group      => group_by

          Tag.select(options[:select])
            .where(options[:conditions])
            .joins(options[:joins])
            .group(options[:group])
            .order(options[:order])
            .limit(options[:limit])
        end

        def tagged *tags
          options = tags.extract_options!
          tags = TagList.from(tags)
          tags.cover_pluralities!
          except = TagList.from(options[:except]) if options[:except]

          conditions = Array(options[:conditions])
          conditions << tags_condition(tags)
          conditions << except_condition(except)  if options[:except]
          conditions << match_all_condition(tags) if options.delete(:match_all)

          select("DISTINCT #{table_name}.*")
            .joins("INNER JOIN taggings
                     ON taggings.taggable_id = #{table_name}.id AND
                        taggings.taggable_type = '#{base_class.name}' " +
                   "INNER JOIN tags ON tags.id = taggings.tag_id")
            .where(conditions.join(" AND "))
        end

        def tags_condition(tags)
          # FIXME how to directly return an empty array from a named scope?
          tags.empty? ? '0 = 1' : '(' + tags.map { |t| sanitize_sql(['tags.name LIKE ?', t]) } * ' OR ' + ')'
        end

        def match_all_condition(tags)
          %((SELECT COUNT(*) FROM taggings INNER JOIN tags ON taggings.tag_id = tags.id
             WHERE taggings.taggable_type = '#{base_class.name}' AND
                   taggable_id = #{table_name}.id AND #{tags_condition(tags)}) >= #{tags.size/2})
        end

        def except_condition(tags)
          %(#{table_name}.id NOT IN
             (SELECT taggings.taggable_id FROM taggings
              INNER JOIN tags ON taggings.tag_id = tags.id
              WHERE #{tags_condition(tags)} AND taggings.taggable_type = '#{base_class.name}') )
        end
      end

      module InstanceMethods
        def tag_list_add *args
          tag_list
          @tag_list.add *args
        end

        def tag_list_remove *args
          tag_list
          @tag_list.remove *args
        end

        def tag_list
          @tag_list ||= cached_tag_list.nil? ? TagList.new(*tags.map(&:name)) : TagList.from(cached_tag_list)
          @tag_list.to_s
        end

        def tag_list=(value)
          @tag_list = TagList.from(value)
        end

        def tag_counts(options = {})
          tag_list
          self.class.tag_counts(options).where(self.class.send(:tags_condition, @tag_list))
        end

        protected

        def cache_tag_list
          self.cached_tag_list = tag_list.to_s
        end

        def save_tags
          return unless @tag_list

          new_tag_names = @tag_list - tags.map(&:name)
          old_tags = tags.reject { |tag| @tag_list.include?(tag.name) }

          self.class.transaction do
            unless old_tags.empty?
              taggings.where(tag_id: old_tags).each(&:destroy)
              taggings.reset
            end
            new_tag_names.each { |name| tags << Tag.find_or_create_by_name(name) }

            duplicate_taggings = taggings.group_by(&:tag_id).values.map { |tags| tags[1..-1] }.flatten
            duplicate_taggings.each(&:destroy)
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Acts::Taggable::ActMacro
