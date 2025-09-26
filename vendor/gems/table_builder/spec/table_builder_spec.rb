require 'spec_helper'

module TableBuilder
  RSpec.describe Cell do
    it 'renders basic cell' do
      html = Cell.new(Row.new(Table.new), 'foo').render
      assert_html html, 'td', 'foo'
    end

    it 'picks th when contained in head' do
      html = Cell.new(Row.new(Head.new(Table.new)), 'foo').render
      assert_html html, 'th', 'foo'
    end
  end

  RSpec.describe Row do
    include TableTestHelper

    it 'renders row with cell' do
      row = build_body_row
      row.cell 'foo'
      assert_html row.render, 'tr td', 'foo'
    end
  end

  RSpec.describe Head do
    include TableTestHelper

    it 'adds a column headers row' do
      head = build_table.head
      assert_html head.render, 'thead' do
        assert_select 'tr th[scope=col]', 'foo'
        assert_select 'tr th[scope=col]', 'bar'
      end
    end

    it 'handles column html options' do
      head = build_table(build_column('foo', :class => 'foo')).head
      assert_html head.render, 'th[scope=col]', 'foo'
    end

    it 'translates head cell content' do
      TableBuilder.options[:i18n_scope] = 'foo'
      head = build_table(build_column(:foo)).head
      assert_html head.render, 'th', 'Translation missing: en.foo.strings.columns.foo'
    end

    it 'handles head with total row' do
      head = build_table.head
      head.row { |r| r.cell "foo", :colspan => :all }
      assert_html head.render, 'thead tr th[colspan=2]', 'foo'
    end
  end

  RSpec.describe Body do
    include TableTestHelper

    it 'renders body' do
      body = build_table.body
      body.row { |row, record| row.cell(record) }
      assert_html body.render, 'tbody' do
        assert_select 'tr td', 'foo'
        assert_select 'tr[class=alternate] td', 'bar'
      end
    end

    it 'handles cell html options' do
      body = build_table.body
      body.row { |row, record| row.cell(record, :class => 'baz') }
      assert_html body.render, 'td.baz', 'foo'
    end
  end

  RSpec.describe Table do
    it 'renders basic table' do
      table = Table.new(nil, %w(a b)) do |table|
        table.column('a'); table.column('b')
        table.row { |row, record| row.cell(record); row.cell(record) }
      end
      assert_html table.render, 'table#strings.list' do
        assert_select 'thead tr th[scope=col]', 'a'
        assert_select 'tbody tr td', 'a'
        assert_select 'tbody tr[class=alternate] td', 'b'
      end
    end

    it 'renders calling column and cell shortcuts' do
      table = Table.new(nil, %w(a b)) do |table|
        table.column 'a', 'b'
        table.row { |row, record| row.cell record, record }
      end
      assert_html table.render, 'table#strings.list' do
        assert_select 'thead tr th[scope=col]', 'a'
        assert_select 'tbody tr td', 'a'
        assert_select 'tbody tr[class=alternate] td', 'b'
      end
    end

    it 'allows block to access view helpers and instance variables' do
      @foo = 'foo'
      def bar; 'bar'; end
      table = Table.new(nil, %w(a)) do |table|
        table.column 'a'
        table.row { |row, record, index| row.cell @foo + bar }
      end
      html = ''
      expect { html = table.render }.not_to raise_error
      expect(html).to match(/foobar/)
    end

    it 'inherits column html class to tbody cells' do
      table = Table.new(nil, %w(a)) do |table|
        table.column 'a', :class => 'foo'
        table.row { |row, record, index| row.cell 'bar' }
      end
      assert_html table.render, 'tbody tr td.foo', 'bar'
    end

    it 'determines table collection name' do
      expect(Table.new(nil, [Object.new]).collection_name).to eq('objects')
    end

    protected

    def bar
      'bar'
    end
  end

  class Record
    attr_reader :id, :title
    def initialize(id, title); @id = id; @title = title; end
    def attribute_names; ['id', 'title']; end
  end

  RSpec.describe 'Rendering', type: :view do
    before do
      articles = [Record.new(1, 'foo'), Record.new(2, 'bar')]
      @view = ActionView::Base.new([File.dirname(__FILE__) + '/../test/fixtures/templates'], { :articles => articles })
      @view.extend(TableBuilder)
      TableBuilder.options[:i18n_scope] = :test
      I18n.backend.send :merge_translations,
        :en, :test => { :'table_builder_records' => { :columns => { :id => 'ID', :title => 'Title' } } }
    end

    it 'renders simple table' do
      html = @view.render(:file => 'table_simple')
      assert_html html, 'table[id=table_builder_records][class=list]' do
        assert_select 'thead tr' do
          assert_select 'th[scope=col]', 'ID'
          assert_select 'th[scope=col]', 'Title'
        end
        assert_select 'tbody' do
          assert_select 'tr' do
            assert_select 'td', '1'
            assert_select 'td', 'foo'
          end
          assert_select 'tr[class=alternate]' do
            assert_select 'td', '2'
            assert_select 'td', 'bar'
          end
        end
      end
    end

    it 'renders auto body same as simple' do
      expect(@view.render(:file => 'table_simple')).to eq(@view.render(:file => 'table_auto_body'))
    end

    it 'renders auto columns' do
      html = @view.render(:file => 'table_auto_columns')
      assert_html html, 'table[id=table_builder_records][class=list]' do
        assert_select 'thead tr' do
          assert_select 'th[scope=col]', 'Id'
          assert_select 'th[scope=col]', 'Title'
        end
        assert_select 'tbody' do
          assert_select 'tr' do
            assert_select 'td', '1'
            assert_select 'td', 'foo'
          end
          assert_select 'tr[class=alternate]' do
            assert_select 'td', '2'
            assert_select 'td', 'bar'
          end
        end
      end
    end

    it 'renders all elements' do
      html = @view.render(:file => 'table_all')
      assert_html html, 'table[id=table_builder_records][class=list]' do
        assert_select 'thead tr' do
          assert_select 'th[colspan=2][class=total]', 'total: 2'
        end
        assert_select 'thead tr' do
          assert_select 'th[scope=col]', 'ID'
          assert_select 'th[scope=col]', 'Title'
          assert_select 'th[scope=col][class=action]', 'Action'
        end
        assert_select 'tbody' do
          assert_select 'tr' do
            assert_select 'td', '1'
            assert_select 'td', 'foo'
          end
          assert_select 'tr[class=alternate]' do
            assert_select 'td', '2'
            assert_select 'td', 'bar'
          end
        end
        assert_select 'tfoot tr td', 'foo'
      end
    end

    it 'renders all with empty collection' do
      view = ActionView::Base.new([File.dirname(__FILE__) + '/../test/fixtures/templates'], { :articles => [] })
      view.extend(TableBuilder)
      html = view.render(:file => 'table_all')
      assert_html html, 'p[class=empty]', 'no records!'
    end
  end
end