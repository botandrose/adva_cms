require 'spec_helper'

RSpec.describe 'Tags::Node helpers' do
  it 'computes parents, self_and_parents, and level' do
    root = Menu::Base.new(:root)
    child = Menu::Base.new(:child)
    grandchild = Menu::Base.new(:grand)

    root.children << child
    child.children << grandchild

    expect(grandchild.parents.map(&:id)).to eq([:child, :root])
    expect(grandchild.self_and_parents.map(&:id)).to eq([:grand, :child, :root])
    expect(root.level).to eq(0)
    expect(child.level).to eq(1)
    expect(grandchild.level).to eq(2)
  end

  it 'supports insert_at_position before/after specific children and ends' do
    owner = Menu::Base.new(:owner)
    a = Menu::Base.new(:a)
    b = Menu::Base.new(:b)
    c = Menu::Base.new(:c)
    owner.children << a << b << c

    # before first
    owner.send(:insert_at_position, Menu::Base.new(:x), :first, nil)
    expect(owner.children.map(&:id).first).to eq(:x)

    # after last
    owner.send(:insert_at_position, Menu::Base.new(:y), nil, :last)
    expect(owner.children.map(&:id).last).to eq(:y)

    # before b
    owner.send(:insert_at_position, Menu::Base.new(:p), :b, nil)
    ids = owner.children.map(&:id)
    expect(ids[ids.index(:b) - 1]).to eq(:p)

    # after b
    owner.send(:insert_at_position, Menu::Base.new(:q), nil, :b)
    ids = owner.children.map(&:id)
    expect(ids[ids.index(:b) + 1]).to eq(:q)
  end

  it 'add_class accumulates and de-duplicates classes' do
    li = Tags::Li.new('x')
    li.send(:add_class, 'active')
    li.send(:add_class, 'active')
    li.send(:add_class, 'new')
    expect(li.options[:class].split(' ')).to match_array(%w[active new])
  end
end

