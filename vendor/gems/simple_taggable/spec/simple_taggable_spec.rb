require 'spec_helper'
require 'simple_taggable'

require "magazine"
require "photo"
require "post"
require "subscription"
require "magazine"
require "user"

RSpec.describe SimpleTaggable do
  # Note: fixtures are loaded via spec_helper for tests that need them

  describe 'tag_counts' do
    it 'works on class' do
      assert_tag_counts Photo.tag_counts, :great => 2, :sucks => 1, :crazy_animal => 1, :animal => 3, :nature => 3
      assert_tag_counts Post.tag_counts, :great => 2, :sucks => 2, :nature => 7
    end

    it 'works on instance' do
      assert_tag_counts @small_dog.tag_counts, :great => 2, :nature => 3, :animal => 3
    end

    it 'works with frequency' do
      assert_tag_counts Photo.tag_counts(:at_least => 2), :great => 2, :animal => 3, :nature => 3
      assert_tag_counts Photo.tag_counts(:at_most => 1), :sucks => 1, :crazy_animal => 1
    end

    it 'works with frequency and condition' do
      counts = Photo.tag_counts(:at_least => 2, :conditions => "tags.name LIKE '%n%'")
      assert_tag_counts counts, :animal => 3, :nature => 3
    end

    it 'works with order and limit' do
      expect(Post.tag_counts(:order => 'count DESC, name', :limit => 2)).to eq([@nature, @great])
    end
  end

  describe 'tag_counts on has_many :through' do
    it 'works correctly' do
      assert_tag_counts User.tag_counts, :great => 1, :sucks => 1, :nature => 1
    end
  end

  describe 'tags and taggings associations' do
    it 'has tags and taggings' do
      expect(@small_dog.taggings).to be_instance_of(Array)
      expect(@small_dog.tags).to be_instance_of(Array)
    end
  end

  describe '#tag_list' do
    it 'returns correct tag list' do
      expect(@small_dog.tag_list.names).to eq(["animal", "great", "nature"])
    end
  end

  describe '#tagged' do
    it 'finds records tagged with the given tags' do
      assert_equivalent [@nature_post, @small_dog, @big_cat], Post.tagged('nature')
      assert_equivalent [@small_dog], Photo.tagged('animal', 'great')
      assert_equivalent [@big_cat, @animal_post], Post.tagged('nature', 'great')
    end

    it 'does not find records tagged with nothing or blank tags' do
      expect(Post.tagged("")).to be_empty
      expect(Post.tagged(nil)).to be_empty
    end

    it 'does not find records tagged with non existant tags' do
      expect(Post.tagged("missing")).to be_empty
    end

    it 'finds records tagged with at least one of the given tags' do
      assert_equivalent [@big_cat, @small_dog, @nature_post, @animal_post], Post.tagged('nature', 'animal')
    end

    it 'finds records tagged with all of the given tags when :match_all option was set' do
      assert_equivalent [@small_dog], Post.tagged('nature', 'animal', :match_all => true)
    end

    it 'works with match_all and include' do
      # TODO: This is a complicated test that needs review
      expect {
        Post.tagged('nature', 'animal', :match_all => true, :include => :user)
      }.not_to raise_error
    end

    it 'works with conditions' do
      assert_equivalent [@nature_post], Post.tagged('nature', :conditions => 'posts.title IS NOT NULL')
    end

    it 'works with :except option' do
      assert_equivalent [@animal_post], Post.tagged('great', :except => @nature_post)
    end

    it 'is plurality-insensitive' do
      expect(Post.tagged('natures')).to eq(Post.tagged('nature'))
    end

    it 'works with association scope' do
      expect(@john.posts.tagged('nature')).not_to be_empty
    end
  end

  describe '#save_tags' do
    it 'saves new tags' do
      assert_difference 'Tag.count', 1 do
        @jane.tag_list = 'computer'
        @jane.save_tags
      end
    end

    it 'removes old tags' do
      assert_difference '@jane.tags.count', -1 do
        @jane.tag_list = 'sucks'
        @jane.save_tags
      end
    end

    it 'deduplicates tags' do
      assert_difference 'Tag.count', 1 do
        @jane.tag_list = 'computer, computer'
        @jane.save_tags
      end
      expect(@jane.tag_list.names).to eq(['computer'])
    end
  end

  describe 'unused tag deletion' do
    it 'deletes unused tags by default' do
      @big_cat.tag_list = ""
      @big_cat.save_tags
      expect { tags(:sucks).reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not delete unused tags when Tag.destroy_unused is set to false' do
      Tag.destroy_unused = false
      @big_cat.tag_list = ""
      @big_cat.save_tags
      expect { tags(:sucks).reload }.not_to raise_error
      Tag.destroy_unused = true
    end
  end

  describe '#tag_list reader and writer' do
    it 'returns a tag list' do
      expect(@jane.tag_list).to be_instance_of(TagList)
      expect(@jane.tag_list.names).to eq(["great", "nature"])
    end

    it 'adds new tags via writer' do
      @jane.tag_list = 'sucks, great, nature'
      @jane.save!

      assert_equivalent [@jane, @big_cat], Post.tagged('sucks')
      assert_tag_counts @jane.tag_counts, :sucks => 1, :great => 1, :nature => 1
    end

    it 'removes tags via writer' do
      @jane.tag_list = 'sucks'
      @jane.save!

      assert_equivalent [@big_cat], Post.tagged('nature')
      assert_tag_counts @jane.tag_counts, :sucks => 1
    end

    it 'works on a new record' do
      post = Post.new
      expect(post.tag_list).to be_instance_of(TagList)
      expect(post.tag_list).to be_empty
    end

    it 'clears tag_list with nil' do
      @jane.tag_list = nil
      expect(@jane.tag_list).to be_empty
    end

    it 'clears tag_list with a string containing only spaces' do
      @jane.tag_list = '   '
      expect(@jane.tag_list).to be_empty
    end

    it 'is reset on reload' do
      @jane.tag_list = 'sucks, great, nature'
      @jane.reload
      expect(@jane.tag_list.names).to eq(["great", "nature"])
    end

    it 'handles changing the case of tags' do
      @jane.tag_list = 'GREAT, NATURE'
      @jane.save!
      expect(@jane.tag_list.names).to eq(["great", "nature"])
    end
  end

  describe 'case insensitivity' do
    it 'is case insensitive' do
      assert_equivalent [@jane], Post.tagged('NATURE')
    end

    it 'handles more case insensitivity scenarios' do
      @jane.tag_list = 'DIFFERENT, NATURE'
      @jane.save!
      assert_equivalent [@jane], Post.tagged('different')
      assert_equivalent [@jane], Post.tagged('DIFFERENT')
    end

    it 'handles even more case insensitivity scenarios' do
      Tag.create(:name => 'DIFFERENT')
      @jane.tag_list = 'DIFFERENT, NATURE'
      @jane.save!
      expect(Tag.where(:name => 'different').count).to eq(1)
      expect(Tag.where(:name => 'DIFFERENT').count).to eq(0)
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
      @jane.tag_list = 'great, sucks'
      expect(@jane.tag_list.names).to eq(['great', 'sucks'])
    end

    it 'uses cached_tag_list' do
      @jane.cached_tag_list = 'great, sucks'
      @jane.save
      expect(@jane.tag_list.names).to eq(['great', 'sucks'])
    end
  end
end