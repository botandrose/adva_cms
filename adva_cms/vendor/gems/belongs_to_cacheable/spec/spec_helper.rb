require 'active_record'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

require File.dirname(__FILE__) + '/../lib/active_record/belongs_to_cacheable.rb'
require File.dirname(__FILE__) + '/../init.rb'

name = "belongs_to_cacheable"
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/#{name}.spec.log")
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

module SpecHelper
  class Article < ActiveRecord::Base
    self.table_name = 'articles'
    
    unless table_exists?
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Schema.define(:version => 1) do
        create_table :articles, :force => true do |t|
          t.string     :title
          t.references :author, :polymorphic => true
          t.string     :author_name
          t.string     :author_email
          t.references :last_author, :polymorphic => true
          t.string     :last_author_name
        end
      end
    end
    
    belongs_to_cacheable :author
    belongs_to_cacheable :last_author
  end
  
  class User < ActiveRecord::Base
    self.table_name = 'users'
    
    unless table_exists?
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Schema.define(:version => 1) do
        create_table :users, :force => true do |t|
          t.string     :name
          t.string     :email
          t.string     :url
        end
      end
    end
  end
end
