# Script to import Dynamic Reaching program's exported CSV file.

## Params
column_name = 'Trial'
startDir = '~/Desktop'

## Code body
require 'Datavyu_API.rb'
java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter

# Prompt user for input file
txtFilter = FileNameExtensionFilter.new('Text file','csv')
jfc = JFileChooser.new(startDir)
jfc.setAcceptAllFileFilterUsed(false)
jfc.setFileFilter(txtFilter)
jfc.setMultiSelectionEnabled(false)
jfc.setDialogTitle('Select PKMAS output file')

ret = jfc.showOpenDialog(javax.swing.JPanel.new())

if ret != JFileChooser::APPROVE_OPTION
  puts "Invalid selection. Aborting."
  return
end

# Load the input file
puts "Opening file"
selectedFile = jfc.getSelectedFile()
infile = File.open(selectedFile.getAbsolutePath(), 'r')

lines = infile.readlines
# Find first row after generate trials has been pressed
start_idx = lines.find_index{ |x| x.split(',').first == '-100' }

lines = lines[start_idx+1..lines.size-1]

# Create cells for each row of data
column = getVariable(column_name)
time = 1e7
lines.each do |line|
  ncell = column.make_new_cell

  tnum, degrees, direction, speed, startpos, stoppos, type = line.split(',')
  dirstr = (direction.strip == '-1')? 'l' : 'r'

  ncell.degrees = degrees.strip
  ncell.speed = speed.strip
  ncell.direction = dirstr
  ncell.onset = time
  ncell.offset = time
  time += 1
end

setVariable(column)

puts 'Finished.'
