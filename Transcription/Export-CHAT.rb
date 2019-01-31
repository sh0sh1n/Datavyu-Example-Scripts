# Convert transcription in Datavyu to CHAT format.
# Adapted from Export-CHAT.rb.

## Parameters
output_folder = '~/Desktop/CHAT/' # :prompt

# Outer key is the ID in CHAT, inner keys are attributes.
# Currenlty handled attributes:
# :location - a Hash with following keys:
# => 	:column = Name of the column as a String (required)
# => 	:code = Name of the code in the column with the transcription (required)
# =>  :cell_filter = function to apply to select cells in the column; omit to export all cells
# :
source_map = { # mapping from transcript_source codes to 3-letter speaker ids
	'PAR'	=>	{
		:location => {
			:column => 'Parent_Utterance',
			:code => 'transcript',
			:cell_filter => nil,
		},
	},
	'CHI'	=>	{
		:location => {
			:column => 'Child_Vocalizations',
			:code => 'transcript',
		}
	}
}

substitutions = {
	 /^b\s*\.?$/ => '&=babbles .'
	# /^c$/ => '&=vocalizes'
}

## Body
require 'Datavyu_API.rb'
require 'date'

java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter

# Globals
utf_marker = '@UTF8'
time_marker = "\x15" # hex code before time marker
language_table = {
	'Afrikaans' => 'af',
	'Arabic' => 'ar',
	'Basque' => 'ba',
	'Cantonese' => 'zh-yue',
	'Catalan' => 'ca',
	'Chinese' => 'zh',
	'Croatian' => 'hr',
	'Danish' => 'da',
	'Dutch' => 'nl',
	'English' => 'en',
	'Estonian' => 'et',
	'Farsi' => 'fa',
	'Finnish' => 'su',
	'French' => 'fr',
	'German' => 'de',
	'Greek' => 'gr',
	'Hebrew' => 'he',
	'Hungarian' => 'hu',
	'Irish' => 'ga',
	'Italian' => 'it',
	'Japanese' => 'ja',
	'Korean' => 'ko',
	'Lithuanian' => 'lt',
	'Polish' => 'pl',
	'Portugese' => 'pt',
	'Romanian' => 'ro',
	'Russuan' => 'ru',
	'Spanish' => 'es',
	'Swedish' => 'sv',
	'Tamil' => 'ta',
	'Thai' => 'th',
	'Turkish' => 'tr',
	'Vietnamese' => 'vi',
	'Welsh' => 'cy'
}

output = []
output << utf_marker
output << '@Begin'

# Iterate over transcript cells
puts "Adding transcription data..."
data = Hash.new { |h, k| h[k] = [] } # collect all the output lines and sort them by onset time before writing to file.
source_map.each_pair do |id, info|
	col = get_column(info[:location][:column])
	filter = info[:location][:cell_filter]
	cells = col.cells
	cells.select!(&filter) unless filter.nil? # apply filter if present

	cells.each do |c|
		transcript = c.get_code(info[:location][:code]).strip

		# Replace using substitutions hash
		substitutions.each_pair { |pattern, replacement| transcript.gsub!(pattern, replacement) }

		# Append a period to transcript unless it has ending.
		transcript += ' .' unless %w(. ? !).any?{ |x| transcript.end_with?(x) }

		# Make sure there is a space before punctuations.
		transcript.gsub!(/(\S+)([,.?!])/, '\\1 \\2')

		line = "*#{id}:\t#{transcript} #{time_marker}#{c.onset}_#{c.offset}#{time_marker}"
		data[c.onset] << line
	end
end

data.sort.map{|x| x[1]}.flatten.each { |x| output << x } # add the lines sorted by onset times

output << '@End'

# Prompt user for output file.
puts "Writing data to file..."

if output_folder.equal?(:prompt)
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

	output_file = jfc.getSelectedFile().getPath()
	output_file += '.cha' unless output_file.end_with?('.cha')
else
	outpath = File.expand_path(output_folder)
	output_file = File.join(outpath, $db.getName().gsub('.opf', '.cha'))
end

# Write data to file.
outfile = File.open(output_file, 'w+')
outfile.puts output
outfile.close
