## Parameters
# folder with csv files of lists of verbs in english and spanish
content_folder = '~/Desktop/PathManner/'
# name of column with transcriptions
transcription_col_name = 'transcribe'
# name of code in column with transcriptions that designates content
content_code_name = 'content'
# name of code in column with transcriptions that designates source
source_code_name = 'source_mco'

# allowed punctuation at end of word
punctuation_list = %w[? ! , .]

## Body
require 'Datavyu_API.rb'
require 'csv'

content_path = File.expand_path(content_folder)
english_files = Dir.chdir(content_path) { Dir.glob('*English*') }
path_file = english_files.select{ |f| f.include?('Path') }.first
manner_file = english_files.select{ |f| f.include?('Manner') }.first

# read CSV file as array of words
path_content = CSV.read(File.join(content_path, path_file),
  encoding: 'iso-8859-1:utf-8')
path_content.flatten!
# get rid of first entry (header)
path_content.delete_at(0)
# read CSV file as array of words
manner_content = CSV.read(File.join(content_path, manner_file),
  encoding: 'iso-8859-1:utf-8')
manner_content.flatten!
# get rid of first entry (header)
manner_content.delete_at(0)

# fetch column with transcriptions
transcribe = get_column(transcription_col_name)

# intiialize columns in which to store verb type matches from transcriptions
path_verbs = new_column('pathverbs', %w[source verbs])
manner_verbs = new_column('mannerverbs', %w[source verbs])

transcribe.cells.each do |c|
  # get the content/transcription for current cell
  content = c.get_code(content_code_name)

  # split content into words
  content_words = content.split(' ')
  # strip words of punctuation as last character
  content_words = content_words.map { |cw|
    (punctuation_list.include?(cw[-1]) ? cw[0..-2] : cw) }
  # strip words of apostrophe s too
  content_words = content_words.map { |cw|
    (cw[-2..-1] == "'s" ? cw[0..-3] : cw) }

  # get initial list of any matches from path/manner verb lists
  # include repeats!
  path_matches = content_words.select{ |cw| path_content.include?(cw) }
  manner_matches = content_words.select{ |cw| manner_content.include?(cw) }

  # populate their columns
  unless path_matches.empty?
    ncell = path_verbs.new_cell()
    ncell.onset = c.onset
    ncell.offset = c.offset
    ncell.source = c.get_code(source_code_name)
    # put commas between all verbs in list as argument
    ncell.verbs = path_matches.join(', ')
  end

  unless manner_matches.empty?
    ncell = manner_verbs.new_cell()
    ncell.onset = c.onset
    ncell.offset = c.offset
    ncell.source = c.get_code(source_code_name)
    # put commas between all verbs in list as argument
    ncell.verbs = manner_matches.join(', ')
  end

end

set_column('pathverbs', path_verbs)
set_column('mannerverbs', manner_verbs)
