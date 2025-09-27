module TableBuilder
  class Body < Rows
    self.tag_name = :tbody

    module RecordIdentifier
      def dom_id(record)
        base = (record.class.name || '').split('::').last || ''
        base = base.empty? ? 'record' : base
        base = base.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase
        if record.respond_to?(:id) && record.id
          "#{base}_#{record.id}"
        else
          "new_#{base}"
        end
      end
    end

    include RecordIdentifier
    
    def row(options = {}, &block)
      table.collection.each_with_index do |record, ix|
        super(record, options_for_record(record, ix, options))
      end
    end

    protected

      def build
        row do |row, record| 
          row.cell *table.columns.map { |column| record.send(column.attribute_name) }
        end if @rows.empty?
      end
    
      def options_for_record(record, ix, options = {})
        options = options.dup
        options[:id] = dom_id(record) if record.respond_to?(:new_record?)
        add_class!(options, 'alternate') if ix % 2 == 1
        options
      end
  end
end
