# Export datavyu columns to .sds format used by GSEQ

## Parameters
input_folder = '~/Desktop/Datavyu'
output_file = '~/Desktop/Data.sds'
factors = {
  'sex' => %w[m f]
}
column_names = %w[column1 column2]
session_id = 'id'
metadata_column = 'id'
delimiter1 = ' '

## Body
require 'Datavyu_API.rb'

# Init storage.
data = []

# Add data type declaration.
data_type = %w[Timed] + column_names
data << data_type.join(delimiter1)

# Add factors.
unless factors.empty?
  data << '*'
  factors.each_pair do |name, values|
    h = "#{name}(#{values.join(delimiter1)})"
    data << h
  end
  data << ';'
end

# Load files
inpath = File.expand_path(input_folder)
infiles = get_datavyu_files_from(inpath)
infiles.each do |infile|
  inpath = File.join(inpath, infile)
  $db, $pj = load_db(inpath)
  puts "Working on #{infile}..."

  metadata_col = get_column(metadata_column)
  metadata_cell = metadata_col.cells.first
  raise "Metadata cell not found! Exiting." if metadata_cell.nil?

  data << nil
  segment_header = ['<', session_id, metadata_cell.get_code(session_id), '>'].join(delimiter1)
  data << segment_header
  data << "(" + factors.keys.map{ |x| metadata_cell.get_code(x) }.join(delimiter1) + ")"
  data << nil

  # Start all files at 0 seconds.
  data << ', 0.000'

  # Add data for each column.
  column_names.each_with_index do |cname, idx|
    data << '&' if idx > 0
    col = get_column(cname)
    col.cells.each do |cell|
      onset = sprintf("%.3f", cell.onset / 1000.0)
      offset = sprintf("%.3f", cell.offset / 1000.0)
      data << "#{cname}, #{onset}-#{offset}"
    end
  end
  data << '/'
end

# Write data to file.
puts 'Writing data to file...'
outpath = File.expand_path(output_file)
outfile = File.open(outpath, 'w+')
outfile.puts data
outfile.close

puts "Finished."
