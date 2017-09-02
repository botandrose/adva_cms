class HasFilterArticle < ActiveRecord::Base
  self.table_name = 'has_filter_articles'
  acts_as_taggable

  has_filter :tagged, :categorized,
             :text  => { :attributes => [:title, :body, :excerpt] },
             :state => { :states => [:published, :unpublished] }

  has_many :categorizations, :class_name => 'HasFilterCategorization', :dependent => :destroy
  has_many :categories, :through => :categorizations, :class_name => 'HasFilterCategory'

  scope :published, -> { where(published: true) }
  scope :approved, -> { where(approved: true) }
end

class HasFilterCategorization < ActiveRecord::Base
  belongs_to :article, :class_name => 'HasFilterArticle'
  belongs_to :category, :class_name => 'HasFilterCategory'
end

class HasFilterCategory < ActiveRecord::Base
end

