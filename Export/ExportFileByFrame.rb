# Export by frame.

## Paramters
code_map = {
  'id' => %w(study subj sex tdate bdate),
  'task' => %w(ordinal task)
}
frame_rate_backup = 30 # default fallback framerate if actual framerate can not be read
delimiter = ','
output_file = :prompt #'~/Desktop/Data.csv'

## Body
require 'Datavyu_API.rb'
java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter

# Init data array
data = []

# Get framerate
fps = Datavyu.getDataController().getCurrentFPS()
fps = frame_rate_backup if (fps.nil? || fps <= 1 )

# Get columns
columns = code_map.keys.each_with_object({}){ |k, h| h[k] = get_column(k) }

# Find range of times with data.
all_cells = columns.values.map{ |x| x.cells }.reduce(:+).flatten
min_time = all_cells.map(&:onset).min
max_time = all_cells.map(&:offset).max

# Add header as first row of data array
header = %w(framenum time) + code_map.map{ |k, v| v.map{ |c| "#{k}_#{c}" } }.flatten
data << header.join(delimiter)

# Iterate from be
interval_size = 1000.0/fps
framenum = 1
ct = min_time # current time
while(ct <= max_time + interval_size)
  row = [framenum, ct]
  code_map.each_pair do |k, v|
    col = columns[k]
    cell = col.cells.find do |x|
      on = x.onset
      off = x.offset
      # This logic is from ExportDatabaseFileC::exportByFrame()
      (on <= ct && off >= ct) || ((off - on).abs < interval_size && on > ct-interval_size+1 && ct >= on && on < ct+interval_size-1)
    end
    vals = (cell.nil?)? [''] * v.size : cell.get_codes(v)
    vals.each{ |x| row << x }
  end
  data << row.join(delimiter)

  framenum += 1
  ct = (ct+interval_size).round
end


# Write to file
puts "Writing data to file..."
if(output_file == :prompt)
 txtFilter = FileNameExtensionFilter.new('Text file','txt')
 csvFilter = FileNameExtensionFilter.new('CSV file', 'csv')
 jfc = JFileChooser.new()
 jfc.setAcceptAllFileFilterUsed(false)
 jfc.setFileFilter(csvFilter)
 jfc.addChoosableFileFilter(txtFilter)
 jfc.setMultiSelectionEnabled(false)
 jfc.setDialogTitle('Select output file.')

 ret = jfc.showSaveDialog(javax.swing.JPanel.new())

 if ret != JFileChooser::APPROVE_OPTION
   puts "Invalid selection. Aborting."
   return
 end

 chosen_file = jfc.getSelectedFile()
 fn = chosen_file.getAbsolutePath()
 outfile = File.open(fn, 'w+')
else
 # Open input file for read
 outfile = File.open(File.expand_path(input_file), 'w+')
end

outfile.puts data
outfile.close
