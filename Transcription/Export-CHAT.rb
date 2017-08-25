# Convert transcription in Datavyu to CHAT format.
# Currently designed to export transcription for PLAY project.

## Parameters
# languages_column_name = 'languages'
# participants_column_name = 'participants'
transcript_column_name = 'transcribe'
transcript_source_code = 'source_mb'
transcript_content_code = 'content'

# Codes from ID column
test_date_code = 'testdate' # code in id column corresponding to test date
birth_date_code = 'birthdate' # "" birth date
site_code = 'site' # "" site
participant_code = 'participant' # "" participant
baby_language1_code = 'babylanguage1'
baby_language2_code = 'babylanguage2'
mom_language1_code = 'momlanguage1'
mom_language2_code = 'momlanguage2'

source_map = { # mapping from transcript_source codes to 3-letter speaker ids
	'm'	=>	{
		:id => 'MOT',
		:name => nil,
		:role => 'Mother'
		# :site => lambda{ get_column('id').cells.first.site },
		# :participant => lambda{ get_column('id').cells.first.participant }
		# :language1 => lambda{ get_column('id').cells.first.momlanguage1 },
		# :language2 => lambda{ get_column('id').cells.first.momlanguage2 }
	},
	'b'	=>	{
		:id => 'CHI',
		:name => nil,
		:role => 'Child'
		# :birthdate => lambda{ get_column('id').cells.first.birthdate }
		# :language1 => lambda{ get_column('id').cells.first.babylanguage1 }
		# :language2 => lambda{ get_column('id').cells.first.babylanguage2 }
	}
}

substitutions = {
	# /^b$/ => '&=babbles', # these are handled manually now
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

# Add participants header from source_map
# NOTE: first name field not implemented yet since birthdate must be anonymized if included
puts "Adding participants header..."
header_participants = "@Participants:\t" + source_map.map{ |k, v| [v[:id], v[:role]].join(' ') }.join(', ')
output << header_participants

# Compute age of infant from test date and birth date.
id_cell = get_column('id').cells.first
bd = Date.parse(id_cell.get_code(birth_date_code))
td = Date.parse(id_cell.get_code(test_date_code))
age = td - bd
yrs = age/365.25
yr = yrs.floor # years
mos = (yrs-yr) * 12
mo = mos.to_f.round(2) # months

# Get primary, secondary language(s) for child and mom
bl = [id_cell.get_code(baby_language1_code), id_cell.get_code(baby_language2_code)].reject{ |x| x == '.' }
bls = (bl.empty?)? '' : bl.join(',')
language_table.each_pair{ |k, v| bls.gsub!(/#{k}/i, v) }

ml = [id_cell.get_code(mom_language1_code), id_cell.get_code(mom_language2_code)].reject{ |x| x == '.' }
mls = (ml.empty?)? '' : ml.join(',')
language_table.each_pair{ |k, v| mls.gsub!(/#{k}/i, v) }

# Add id headers for mom and baby.
puts "Adding ID headers..."
header_mom = "@ID:\t#{bls}|PLAY#{id_cell.get_code(site_code)}|MOT||||#{id_cell.get_code(participant_code)}|Mother|||"
header_child = "@ID:\t#{mls}|PLAY#{id_cell.get_code(site_code)}|CHI|#{yr};#{mo}|||#{id_cell.get_code(participant_code)}|Child|||"
output << header_mom << header_child

# Iterate over transcript cells
puts "Adding transcription data..."
transcript_col = get_column(transcript_column_name)
transcript_col.cells.each do |tc|
	speaker = tc.get_code(transcript_source_code)
	transcript = tc.get_code(transcript_content_code).strip

	# Replace using substitutions hash
	transcript.gsub!(Regexp.union(substitutions.keys), substitutions) unless substitutions.empty?

	# For infant/child, lookup coding in babyutterancetype column for babbles and cries
	# and substitute appropriately.
	if(transcript == 'c')
		utterance_cell = get_column('babyutterancetype').cells.find{ |x| x.onset == tc.onset }
		case(utterance_cell.crygrunt_cg)
		when('c')
			transcript = '&=cry'
		when('g')
			transcript = '&=grunt'
		else
			raise "Unhandled cry utterance type."
		end
	elsif(transcript == 'b')
		transcript = '&=babble'
	end
	
	# Append a period to transcript unless it has ending.
	transcript += ' .' unless %w(. ? !).any?{ |x| transcript.end_with?(x) }

	# Make sure there is a space before punctuations.
	transcript.gsub!(/([^ ])([,.?!])/, '\\1 \\2')

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
