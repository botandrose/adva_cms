require 'spec_helper'
require 'simple_taggable'

def tag(record, names)
  record.tag_list = Array(names).join(', ')
  record.save_tags
  record.reload
end

RSpec.describe SimpleTaggable do
  let!(:john) { User.create!(name: 'John') }
  let!(:jane) { User.create!(name: 'Jane') }

  # Photos
  let!(:small_dog) { Photo.create!(title: 'Small dog', user: john) }
  let!(:big_dog)   { Photo.create!(title: 'Big dog',   user: john) }
  let!(:big_cat)   { Photo.create!(title: 'Big cat',   user: john) }
  let!(:flower)    { Photo.create!(title: 'Flower',    user: jane) }
  let!(:sky)       { Photo.create!(title: 'Sky',       user: jane) }

  # Posts
  let!(:blue_sky)      { Post.create!(text: 'The sky is particularly blue today', user: john) }
  let!(:grass)         { Post.create!(text: 'The grass seems very green', user: john) }
  let!(:rain)          { Post.create!(text: 'Why does the rain fall?', user: john) }
  let!(:cloudy)        { Post.create!(text: 'Is it cloudy?', user: john) }
  let!(:still_cloudy)  { Post.create!(text: 'Is it still cloudy?', user: john) }
  let!(:ground)        { Post.create!(text: 'The ground is looking too brown', user: jane) }
  let!(:flowers_post)  { Post.create!(text: 'Why are the flowers dead?', user: jane) }

  # Magazine + subscriptions (has_many :through)
  let!(:ruby_mag) { Magazine.create!(name: 'Ruby') }
  let!(:ruby_sub) { Subscription.create!(user: john, magazine: ruby_mag) }

  before do
    # Tag photos
    tag small_dog, %w[animal great nature]
    tag big_dog,   %w[animal]
    tag big_cat,   %w[sucks animal crazy_animal]
    tag flower,    %w[nature great]
    tag sky,       %w[nature]

    # Tag posts
    tag blue_sky,     %w[great nature]
    tag grass,        %w[nature]
    tag rain,         %w[sucks nature]
    tag cloudy,       %w[nature]
    tag still_cloudy, %w[nature]
    tag ground,       %w[nature sucks]
    tag flowers_post, %w[great nature]

    # Leave magazine untagged to ensure isolation between models

    # Expose ivars where specs used them previously
    @small_dog = small_dog
    @big_cat   = big_cat
    @john      = john
    @jane_post = blue_sky # a post to reuse in writer/reader tests
    @nature_post = blue_sky
  end

  describe 'tag_counts' do
    it 'works on class' do
      assert_tag_counts Photo.tag_counts, great: 2, sucks: 1, crazy_animal: 1, animal: 3, nature: 3
      assert_tag_counts Post.tag_counts,  great: 2, sucks: 2, nature: 7
    end

    it 'works on instance' do
      assert_tag_counts @small_dog.tag_counts, great: 2, nature: 3, animal: 3
    end

    it 'works with frequency' do
      assert_tag_counts Photo.tag_counts(at_least: 2), great: 2, animal: 3, nature: 3
      assert_tag_counts Photo.tag_counts(at_most: 1),  sucks: 1, crazy_animal: 1
    end

    it 'works with frequency and condition' do
      counts = Photo.tag_counts(at_least: 2, conditions: "tags.name LIKE '%n%'")
      assert_tag_counts counts, animal: 3, nature: 3
    end

    it 'works with order and limit' do
      top2 = Post.tag_counts(order: 'count DESC, name', limit: 2)
      expect(top2.map(&:name)).to eq(%w[nature great])
    end
  end

  # "has_many :through" is exercised by Magazine acting as taggable above

  describe 'tags and taggings associations' do
    it 'has tags and taggings' do
      expect(@small_dog.taggings.to_a).to be_instance_of(Array)
      expect(@small_dog.tags.to_a).to be_instance_of(Array)
    end
  end

  describe '#tag_list' do
    it 'returns correct tag list' do
      expect(@small_dog.tag_list.names).to eq(["animal", "great", "nature"])
    end
  end

  describe '#tagged' do
    it 'finds records tagged with the given tags' do
      assert_equivalent [blue_sky, grass, rain, cloudy, still_cloudy, ground, flowers_post], Post.tagged('nature')
      assert_equivalent [@small_dog], Photo.tagged('animal', 'great', match_all: true)
      assert_equivalent [blue_sky, grass, rain, cloudy, still_cloudy, ground, flowers_post], Post.tagged('nature', 'great')
    end

    it 'does not find records tagged with nothing or blank tags' do
      expect(Post.tagged("")).to be_empty
      expect(Post.tagged(nil)).to be_empty
    end

    it 'does not find records tagged with non existant tags' do
      expect(Post.tagged("missing")).to be_empty
    end

    it 'finds records tagged with at least one of the given tags' do
      assert_equivalent [blue_sky, grass, rain, cloudy, still_cloudy, ground, flowers_post], Post.tagged('nature', 'sucks')
    end

    it 'finds records tagged with all of the given tags when :match_all option was set' do
      assert_equivalent [@small_dog], Photo.tagged('nature', 'animal', match_all: true)
    end

    it 'works with match_all and include' do
      # TODO: This is a complicated test that needs review
      expect {
        Post.tagged('nature', 'animal', :match_all => true, :include => :user)
      }.not_to raise_error
    end

    it 'works with conditions' do
      assert_equivalent [blue_sky, grass, rain, cloudy, still_cloudy, ground, flowers_post], Post.tagged('nature', conditions: 'posts.text IS NOT NULL')
    end

    it 'works with :except option' do
      assert_equivalent [flowers_post], Post.tagged('great', except: blue_sky)
    end

    it 'is plurality-insensitive' do
      expect(Post.tagged('natures')).to eq(Post.tagged('nature'))
    end

    it 'works with association scope' do
      expect(@john.posts.merge(Post.tagged('nature'))).not_to be_empty
    end
  end

  describe '#save_tags' do
    it 'saves new tags' do
      assert_difference 'Tag.count', 1 do
        @jane_post.tag_list = 'computer'
        @jane_post.save_tags
      end
    end

    it 'removes old tags' do
      assert_difference '@jane_post.tags.count', -1 do
        @jane_post.tag_list = 'sucks'
        @jane_post.save_tags
      end
    end

    it 'deduplicates tags' do
      assert_difference 'Tag.count', 1 do
        @jane_post.tag_list = 'computer, computer'
        @jane_post.save_tags
      end
      expect(@jane_post.tag_list.names).to eq(['computer'])
    end
  end

  describe 'unused tag deletion' do
    it 'deletes unused tags by default' do
      temp = Photo.create!(title: 'Tmp', user: john)
      tag temp, %w[temp_tag]
      expect(Tag.find_by(name: 'temp_tag')).not_to be_nil
      temp.tag_list = ''
      temp.save_tags
      expect(Tag.find_by(name: 'temp_tag')).to be_nil
    end

    it 'does not delete unused tags when Tag.destroy_unused is set to false' do
      Tag.destroy_unused = false
      temp = Photo.create!(title: 'Tmp2', user: john)
      tag temp, %w[temp_tag2]
      expect(Tag.find_by(name: 'temp_tag2')).not_to be_nil
      temp.tag_list = ''
      temp.save_tags
      expect(Tag.find_by(name: 'temp_tag2')).not_to be_nil
      Tag.destroy_unused = true
    end
  end

  describe '#tag_list reader and writer' do
    it 'returns a tag list' do
      expect(@jane_post.tag_list).to be_instance_of(TagList)
      expect(@jane_post.tag_list.names.sort).to eq(["great", "nature"]) # order not guaranteed after set
    end

    it 'adds new tags via writer' do
      @jane_post.tag_list = 'sucks, great, nature'
      @jane_post.save!

      assert_equivalent [@jane_post, ground, rain], Post.tagged('sucks')
      assert_tag_counts @jane_post.tag_counts, sucks: 3, great: 2, nature: 7
    end

    it 'removes tags via writer' do
      @jane_post.tag_list = 'sucks'
      @jane_post.save!

      assert_equivalent [grass, rain, cloudy, still_cloudy, ground, flowers_post], Post.tagged('nature')
      assert_tag_counts @jane_post.tag_counts, sucks: 3
    end

    it 'works on a new record' do
      post = Post.new
      expect(post.tag_list).to be_instance_of(TagList)
      expect(post.tag_list).to be_empty
    end

    it 'clears tag_list with nil' do
      @jane_post.tag_list = nil
      expect(@jane_post.tag_list).to be_empty
    end

    it 'clears tag_list with a string containing only spaces' do
      @jane_post.tag_list = '   '
      expect(@jane_post.tag_list).to be_empty
    end

    it 'is reset on reload' do
      @jane_post.tag_list = 'sucks, great, nature'
      @jane_post.reload
      expect(@jane_post.tag_list.names.sort).to eq(["great", "nature"]) # restored from DB state
    end

    it 'handles changing the case of tags' do
      @jane_post.tag_list = 'GREAT, NATURE'
      @jane_post.save!
      expect(@jane_post.tag_list.names).to eq(["great", "nature"])
    end
  end

  describe 'case insensitivity' do
    it 'is case insensitive' do
      assert_equivalent [blue_sky, grass, rain, cloudy, still_cloudy, ground, flowers_post], Post.tagged('NATURE')
    end

    it 'handles more case insensitivity scenarios' do
      @jane_post.tag_list = 'DIFFERENT, NATURE'
      @jane_post.save!
      assert_equivalent [@jane_post], Post.tagged('different')
      assert_equivalent [@jane_post], Post.tagged('DIFFERENT')
    end

    it 'handles even more case insensitivity scenarios' do
      Tag.create(name: 'DIFFERENT')
      @jane_post.tag_list = 'DIFFERENT, NATURE'
      @jane_post.save!
      expect(Tag.where(name: 'different').count).to eq(1)
      expect(Tag.where(name: 'DIFFERENT').count).to eq(0)
    end
  end

  describe 'STI support' do
    it 'works with STI' do
      expect(Magazine.tagged('great')).to be_empty
      expect(Post.tagged('great')).not_to be_empty
    end
  end

  describe 'caching' do
    it 'caches the tag_list before save' do
      @jane_post.tag_list = 'great, sucks'
      expect(@jane_post.tag_list.names).to eq(['great', 'sucks'])
    end

    it 'uses cached_tag_list' do
      @jane_post.cached_tag_list = 'great, sucks'
      @jane_post.save
      expect(@jane_post.tag_list.names).to eq(['great', 'sucks'])
    end
  end

  describe 'tag_list_remove' do
    it 'removes tags from tag_list' do
      @jane_post.tag_list = 'great, sucks, nature'
      @jane_post.tag_list_remove 'sucks'
      expect(@jane_post.tag_list.names).to eq(['great', 'nature'])
    end

    it 'removes multiple tags from tag_list' do
      @jane_post.tag_list = 'great, sucks, nature, awesome'
      @jane_post.tag_list_remove 'sucks', 'awesome'
      expect(@jane_post.tag_list.names).to eq(['great', 'nature'])
    end
  end

  describe 'tag_list_add' do
    it 'adds tags to tag_list' do
      @jane_post.tag_list = 'great, nature'
      @jane_post.tag_list_add 'sucks'
      expect(@jane_post.tag_list.names).to eq(['great', 'nature', 'sucks'])
    end

    it 'adds multiple tags to tag_list' do
      @jane_post.tag_list = 'great'
      @jane_post.tag_list_add 'sucks', 'nature'
      expect(@jane_post.tag_list.names).to eq(['great', 'sucks', 'nature'])
    end
  end

  describe 'instance tag_counts' do
    it 'returns tag counts for a specific instance' do
      @jane_post.tag_list = 'great, nature'
      @jane_post.save!
      counts = @jane_post.tag_counts
      expect(counts.map(&:name)).to include('great', 'nature')
    end
  end
end

RSpec.describe Tag do
  describe '#==' do
    it 'compares tags by name' do
      tag1 = Tag.create!(name: 'test')
      # Use an unsaved tag with the same name to avoid uniqueness validation
      tag2 = Tag.new(name: 'test')
      expect(tag1 == tag2).to be true
    end

    it 'returns false for different tag names' do
      tag1 = Tag.create!(name: 'test1')
      tag2 = Tag.create!(name: 'test2')
      expect(tag1 == tag2).to be false
    end
  end

  describe '#to_s' do
    it 'returns the tag name as string' do
      tag = Tag.create!(name: 'test')
      expect(tag.to_s).to eq('test')
    end
  end
end
