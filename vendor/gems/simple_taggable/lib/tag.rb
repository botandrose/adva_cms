class Tag < ActiveRecord::Base
  has_many :taggings
  has_many :taggables, :through => :taggings, :source_type => "Content"

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: true

  cattr_accessor :destroy_unused
  self.destroy_unused = true
  
  class << self
    def find_or_create_by_name(name)
      where(["name LIKE ?", name]).first || create(name: name)
    end
  end

  def count
    read_attribute(:count).to_i
  end

  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end

  def to_s
    name
  end
  alias :to_param :to_s
end


