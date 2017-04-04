# Script to print baby location data for use with Matlab

## Params
outfolder = File.expand_path('~/Desktop')

## Body
require 'Datavyu_API.rb'

col = getVariable('floortime')
if col.nil? || col.cells.size == 0
  puts "No location cells found."
  return
end
data = []

session_cell = getColumn('session').cells.first
prev_offset = session_cell.onset
col.cells.each do |cell|
  if cell.onset - prev_offset > 1
    data << [prev_offset, cell.onset - 1, 100].join(',')
  end
  data << [cell.onset, cell.offset, 0].join(',')
  prev_offset = cell.offset + 1
end
if(session_cell.offset - prev_offset > 1)
  data << [prev_offset, session_cell.offset, 100].join(',')
end

outfile = File.new(File.join(outfolder, $db.getName().gsub('.opf', '') + '_blocations.csv'), 'w+')
outfile.puts data
outfile.close
