module Menus
  module Admin
    # will be concatenated onto existing sites menu via javascript
    class Sites < Menu::Group
      define do
        namespace :admin
        menu :left, :class => 'main' do
          item :comments, :action => :index, :resource => :comment
        end
      end
    end

    class Comments < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:comments)

        menu :left, :class => 'left' do
          item :comments, :action => :index, :resource => :comment
        end
      end
    end
  end
end
