# Convert transcription in Datavyu to CHAT format.
# Currently designed to export transcription for PLAY project.

## Parameters
# languages_column_name = 'languages'
# participants_column_name = 'participants'
transcript_column_name = 'transcribe'
transcript_source_code = 'source_mb'
transcript_content_code = 'content'
source_map = { # mapping from transcript_source codes to 3-letter speaker ids
	'm'	=>	{
		:id => 'MOT',
		:name => nil,
		:role => 'Mother'
	},
	'b'	=>	{
		:id => 'CHI',
		:name => nil,
		:role => 'Child'
	}
}

substitutions = {
	'[grunt]' => '&=grunts',
	'[babble]' => '&=babbles',
	'[cry]' => '&=cries'
}

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
## Body
require 'Datavyu_API.rb'
require 'date'
java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter

utf_marker = '@UTF8'
time_marker = "\x15" # hex code before time marker

output = []
output << utf_marker
output << '@Begin'

# Add participants header from source_map
# NOTE: first name field not implemented yet since birthdate must be anonymized if included
puts "Adding participants header..."
header_participants = "@Participants:\t" + source_map.map{ |k, v| [v[:id], v[:role]].join(' ') }.join(', ')
output << header_participants

# Compute age of infant from test date and birth date.
id_cell = get_column('id').cells.first
bd = Date.parse(id_cell.birthdate)
td = Date.parse(id_cell.testdate)
age = td - bd
yrs = age/365.25
yr = yrs.floor # years
mos = (yrs-yr) * 12
mo = mos.to_f.round(2) # months

# Get primary, secondary language(s) for child and mom
bl = [id_cell.babylanguage1, id_cell.babylanguage2].reject{ |x| x == '.' }
bls = (bl.empty?)? '' : bl.join(',')
language_table.each_pair{ |k, v| bls.gsub!(/#{k}/i, v) }

ml = [id_cell.momlanguage1, id_cell.momlanguage2].reject{ |x| x == '.' }
mls = (ml.empty?)? '' : ml.join(',')
language_table.each_pair{ |k, v| mls.gsub!(/#{k}/i, v) }

# Add id headers for mom and baby.
puts "Adding ID headers..."
header_mom = "@ID:\t#{bls}|PLAY#{id_cell.site}|MOT||||#{id_cell.participant}|Mother|||"
header_child = "@ID:\t#{mls}|PLAY#{id_cell.site}|CHI|#{yr};#{mo}|||#{id_cell.participant}|Child|||"
output << header_mom << header_child

# Iterate over transcript cells
puts "Adding transcription data..."
transcript_col = get_column(transcript_column_name)
transcript_col.cells.each do |tc|
	speaker = tc.get_code(transcript_source_code)
	transcript = tc.get_code(transcript_content_code).strip

	# Append a period to transcript unless it has ending.
	transcript += ' .' unless %w(. ? !).any?{ |x| transcript.end_with?(x) }

	# Make sure there is a space before punctuations.
	transcript.gsub!(/([^ ])([,.?!])/, '\\1 \\2')

	# Replace using substitutions hash
	transcript.gsub!(Regexp.union(substitutions.keys), substitutions)

	line = "*#{source_map[speaker][:id]}:\t#{transcript} #{time_marker}#{tc.onset}_#{tc.offset}#{time_marker}"
	output << line
end
output << '@End'

# Prompt user for output file.
puts "Writing data to file..."
rbFilter = FileNameExtensionFilter.new('Chat file','cha')
jfc = JFileChooser.new()
jfc.setAcceptAllFileFilterUsed(false)
jfc.setFileFilter(rbFilter)
jfc.setMultiSelectionEnabled(false)
jfc.setDialogTitle('Select file to export data to.')

ret = jfc.showSaveDialog(javax.swing.JPanel.new())

if ret != JFileChooser::APPROVE_OPTION
	puts "Invalid selection. Aborting."
	return
end

output_file = jfc.getSelectedFile().getPath()
output_file += '.cha' unless output_file.end_with?('.cha')

# Write data to file.
outfile = File.open(output_file, 'w+')
outfile.puts output
outfile.close
####
# Get the languages and construct the languages header
# lang_cells = get_column(languages_column_name).cells
# header_languages = '@Languages:\t' + lang_cells.map{ |x| x.language }.join(', ')
