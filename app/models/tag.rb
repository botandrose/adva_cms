class Tag < ActsAsTaggableOn::Tag
  has_many :taggables, through: :taggings, source: :taggable, source_type: "Content"

  def to_param = name
end
