require File.expand_path(File.dirname(__FILE__) + "/spec_helper.rb")

Article = SpecHelper::Article
User = SpecHelper::User

describe "belongs_to_cacheable:", "the attributes helper method" do
  it "finds the expected cached attribute names for author" do
    names = Article.new.cached_attributes_for(:author)
    names.should == ["name", "email"]
  end
  
  it "finds the expected cached attribute names for last_author" do
    names = Article.new.cached_attributes_for(:last_author)
    names.should == ["name"]
  end
end

describe "belongs_to_cacheable:" do
  before :each do
    @author = User.new :name => 'the author name', :email => 'author@email.org'
    @article = Article.new 
  end
  
  it "caches the expected author attribute values" do
    @article.author = @author
    @article.send :cache_author_attributes!
    values = [:author_name, :author_email].map{|attribute| @article.send attribute }
    values.should == ['the author name', 'author@email.org']
  end
  
  it "caches the expected author attribute values" do
    @article.last_author = @author
    @article.send :cache_last_author_attributes!
    values = [:last_author_name].map{|attribute| @article.send attribute }
    values.should == ['the author name']
  end
  
  it "instantiates a new User object with the cached attributes as a default" do
    @article.author_type = 'User'
    @article.author_name = 'the cached author name'
    @article.author_email = 'cached_author@email.org'
    author = @article.send :instantiate_from_cached_attributes, :author, ["name", "email"]
    values = [:name, :email].map{|attribute| author.send attribute }
    values.should == ['the cached author name', 'cached_author@email.org']
  end
  
  it "when the attributes are not cached yet they are fetched from the association object" do
    @article.author = @author
    values = [@article.author_name, @article.author_email]
    values.should == ['the author name', 'author@email.org']
  end

  it "is_author? returns true when comparing with the same author object" do
    @article.author = @author
    @article.is_author?(@author).should be true
  end

  it "is_author? returns false when comparing with a different author object" do
    other_author = User.new :name => 'other author', :email => 'other@email.org'
    @article.author = @author
    @article.is_author?(other_author).should be false
  end

  it "is_last_author? returns true when comparing with the same last_author object" do
    @article.last_author = @author
    @article.is_last_author?(@author).should be true
  end

  it "is_last_author? returns false when comparing with a different last_author object" do
    other_author = User.new :name => 'other author', :email => 'other@email.org'
    @article.last_author = @author
    @article.is_last_author?(other_author).should be false
  end
end
