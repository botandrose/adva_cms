class User < ActiveRecord::Base
  acts_as_authenticated_user

  # TODO how do we work this in?
  #  acts_as_authenticated_user :token_with => 'Authentication::SingleToken',
  #                             :authenticate_with => nil

  scope :verified, -> { where.not(verified_at: nil) }
  scope :admin, -> { where(admin: true) }

  has_many :memberships, :dependent => :delete_all
  has_many :sites, :through => :memberships

  validates_presence_of     :first_name, :email
  validates_uniqueness_of   :email, case_sensitive: false
  validates_length_of       :first_name, :within => 1..40
  validates_length_of       :last_name, :allow_nil => true, :within => 0..40
  validates_format_of       :email, :allow_nil => true,
    :with => /(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i

  validates_presence_of     :password,                         :if => :password_required?
  validates_length_of       :password, :within => 12..128,     :if => :password_required?
  validate                  :password_complexity,              :if => :password_required?

  class << self
    def authenticate(credentials)
      return false unless user = User.find_by_email(credentials[:email])
      user.authenticate(credentials[:password]) ? user : false
    end

    def anonymous(attributes = {}) # FIXME rename to build_anonymous
      attributes[:anonymous] = true
      new attributes
    end
  end

  def attributes=(attributes)
    attributes.symbolize_keys!
    memberships = attributes.delete :memberships
    super.tap do
      update_memberships memberships if memberships
    end
  end

  def update_memberships(memberships)
    memberships.each do |site_id, active|
      site = Site.find(site_id)
      if active
        self.sites << site unless member_of?(site)
      else
        self.sites.delete(site) if member_of?(site)
      end
    end
  end

  def member_of?(site)
    sites.include?(site)
  end

  def verified?
    !verified_at.nil?
  end

  def verify!
    update verified_at: Time.zone.now if verified_at.nil?
  end

  # def restore!
  #   update deleted_at: nil if deleted_at
  # end

  def registered?
    !new_record? && !anonymous?
  end

  def name=(name)
    self.first_name = name
  end

  def name
    last_name ? "#{first_name} #{last_name}" : first_name
  end

  def to_s
    name
  end

  def email_with_name
    "#{name} <#{email}>"
  end

  def homepage
    return nil unless self[:homepage]

    self[:homepage][0..6] == 'http://' ? self[:homepage] : 'http://' + self[:homepage]
  end

  def first_name_from_email
    self.first_name.blank? && self.email ? self.email.split('@').first : self.first_name
  end

  protected

    def password_required?
      !anonymous? && (password_hash.nil? || password.present?)
    end

    def password_complexity
      return unless password.present?

      character_types = 0
      character_types += 1 if password.match?(/[a-z]/)      # lowercase
      character_types += 1 if password.match?(/[A-Z]/)      # uppercase
      character_types += 1 if password.match?(/[0-9]/)      # numbers
      character_types += 1 if password.match?(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/) # symbols

      if character_types < 3
        errors.add(:password, 'must contain at least 3 of the following: lowercase letters, uppercase letters, numbers, or special characters')
      end
    end
end
