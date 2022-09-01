class Comment < ActiveRecord::Base
  class CommentNotAllowed < StandardError; end

  def self.approved
    where :approved => true
  end

  def self.unapproved
    where :approved => false
  end

  define_model_callbacks :approve, :unapprove

  def around_save
    if just_approved?
      run_callbacks(:approve) { yield }
    elsif just_unapproved?
      run_callbacks(:unapprove) { yield }
    else
      yield
    end
  end

  after_save do
    commentable.touch
  end

  filtered_column :body
  filters_attributes :sanitize => :body_html

  has_filter :text  => { :attributes => [:body] },
             :state => { :states => [:approved, :unapproved] }

  belongs_to :site
  belongs_to :section
  belongs_to :commentable, :polymorphic => true
  # make sure we're storing the base clase for STI
  def commentable_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end
  has_many :activities, :as => :object

  composed_of :author, :class_name => "User", :mapping => [ %w(author_name name), %w(author_email email) ]

  validates_presence_of :body, :commentable, :author_name, :author_email
  validates_email_format_of :author_email

  before_validation :set_owners
  before_create :authorize_commenting

  def owner
    commentable
  end

  def filter
    commentable.comment_filter
  end

  def unapproved?
    !approved?
  end

  def just_approved?
    approved_changed? and approved?
  end

  def just_unapproved?
    approved_changed? and unapproved?
  end

  def state_changes
    state_changes = if just_approved?
      [:approved]
    elsif just_unapproved?
      [:unapproved]
    end || []
    super + state_changes
  end

  protected

    def authorize_commenting
      if commentable && !commentable.accept_comments?
        raise CommentNotAllowed, I18n.t(:'adva.comments.messages.not_allowed')
      end
    end

    def set_owners
      if commentable # TODO in what cases would commentable be nil here?
        self.site = commentable.site
        self.section = commentable.section
      end
    end
end
