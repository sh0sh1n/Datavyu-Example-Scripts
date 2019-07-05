# Script to mimic default csv export.

## Parameters
output_file = :prompt
columns_to_export = :all
delimiter = ','

## Body
require 'Datavyu_API'
require 'csv'

# Assemble data
columns = case columns_to_export
          when :all
            get_column_list.map { |x| get_column x }
          when Array
            columns_to_export.map { |x| get_column x }
          else
            raise 'invalid columns_to_export parameter'
          end

max_ord = columns.map(&:cells)
                 .flatten
                 .map(&:ordinal)
                 .max

# Write header
header = columns.map do |col|
  (%w[ordinal onset offset] + col.arglist).map { |code| "#{col.name}.#{code}" }
end.flatten
data = CSV.new('', col_sep: delimiter, headers: header, write_headers: true)

# Iterate over ordinals and add data
(0..(max_ord - 1)).each do |ord|
  cells = columns.map { |x| x.cells.size > ord ? x.cells[ord] : x.new_cell }
  codes = cells.map do |cell|
    if cell.ordinal.zero?
      [''] * (3 + cell.arglist.size)
    else
      [cell.ordinal, cell.onset, cell.offset] + cell.get_codes(cell.arglist)
    end
  end
  row = codes.flatten
  data << row
end

# Write data to file
puts 'Writing data to file...'
outfile = case output_file
          when :prompt
            java_import javax.swing.JFileChooser
            java_import javax.swing.JPanel

            jfc = JFileChooser.new
            jfc.setMultiSelectionEnabled(false)
            jfc.setDialogTitle('Select file to export data to.')

            ret = jfc.showSaveDialog(javax.swing.JPanel.new)

            if ret != JFileChooser::APPROVE_OPTION
              puts 'Invalid selection. Aborting.'
              return
            end

            File.open(jfc.getSelectedFile.getPath, 'w+')
          when String
            File.open(File.expand_path(output_file), 'w+')
          else
            raise 'invalid output_file parameter'
          end

outfile.puts data.string
outfile.close

puts 'Finished.'
