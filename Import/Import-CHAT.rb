# Import data from CHAT format (.cha file) to Datavyu.

## Parameters
source_map = { # mapping transcript ID to struct
	'MOT'	=>	{
		:column => 'momspeech',
		:code => 'content'
	},
	'CHI'	=>	{
		:column => 'childspeech',
		:code => 'content'
	},
  'FAT' => {
    :column => 'fatherspeech',
    :code => 'content'
  },
  'SIS' => {
    :column => 'sisterspeech',
    :code => 'content'
  }
}
append_to_columns = false

## Body
require 'Datavyu_API.rb'

java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter

# Prompt user for input file.
chaFilter = FileNameExtensionFilter.new('Chat file','cha')
jfc = JFileChooser.new()
jfc.setAcceptAllFileFilterUsed(false)
jfc.setFileFilter(chaFilter)
jfc.setMultiSelectionEnabled(false)
jfc.setDialogTitle('Select file to export data to.')

ret = jfc.showSaveDialog(javax.swing.JPanel.new())

if ret != JFileChooser::APPROVE_OPTION
	puts "Invalid selection. Aborting."
	return
end

input_file = jfc.getSelectedFile().getPath()

infile = File.open(input_file, 'r')

# Prep columns for import.
column_map = Hash.new
source_map.each_pair do |id, loc|
  colname = loc[:column]
  codename = loc[:code]
  col = (append_to_columns && get_column_list.include?(colname))? get_column(colname) : new_column(colname, codename)
  column_map[id] = col
end

last_offset = 0
infile.each_line do |line|
  next unless line.start_with?('*') # only process main lines

  # puts line
  # p line.bytes

  speaker = line[1..3]
  m = line.match(/\*[A-Z]{3}\:\s+(?<content>.+)(\x15(?<onset>\d+)_(?<offset>\d+)\x15)\n/)
  # p m
  onset = m['onset']
  offset = m['offset']
  content = m['content'].strip

  col = column_map[speaker]
  ncell = col.new_cell()
  if onset.nil?
    last_offset += 1
    ncell.onset = last_offset
    ncell.offset = last_offset
  else
    ncell.onset = onset.to_i
    ncell.offset = offset.to_i # assume offset not nil if onset not nil
    last_offset = offset.to_i
  end

  code = source_map[speaker][:code]
  ncell.change_code(code, content)
end

column_map.values.each{ |x| set_column(x) }
