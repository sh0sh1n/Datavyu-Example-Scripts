## Parameters
#RL_36_B_ML2 copy.opf
# file with list of words/phrases of interest in english
content_file = '~/Desktop/English Word List EDL.csv'
# allowed punctuation at end of word
punctuation_list = %w[? ! , .]

## Body
require 'Datavyu_API.rb'
require 'csv'

CSV.open(File.expand_path(content_file))

# get the transcribe column
transcribe = get_column('momspeech')

# read CSV file as array of words
# take the first element of every row
key_content = CSV.read(File.expand_path(content_file)).map { |r| r[0] }
# strange bug where sometimes a space is inserted before the first character of
# the first entry upon reading CSV file. do this for now:
key_content[0] = 'one'

# get list of all phrase lengths in list
content_length = key_content.map { |c| c.split(' ').length }.uniq

# initialize a new column to store content matches in
english_mathwords = new_column('mathwords','words')

# if english_categories column does not exist, then make it
# otherwise fetch the existing column
# this way we don't overwrite manual coding done in categories column
unless get_column_list.include?('mathcategories')
  # intialize a new column to store word categories in as well
  english_categories = new_column('mathcategories',%w[number function order sing_ref shapes mag_comp
    loc_dir or deictics feat_prop time false])
  else
    english_categories = get_column('mathcategories')
end

# loop through cells in transcribe column
transcribe.cells.each do |tcell|

  # get the content/transcription for current cell
  content = tcell.content

  # split content into words
  content_words = content.split(' ')
  # strip words of punctuation as last character
  content_words = content_words.map { |cw|
    (punctuation_list.include?(cw[-1]) ? cw[0..-2] : cw) }
  # strip words of apostrophe s too
  content_words = content_words.map { |cw|
    (cw[-2..-1] == "'s" ? cw[0..-3] : cw) }

  # get initial list of any words that are contained in key content list
  # include repeats!
  key_words = content_words.select{ |cw| key_content.include?(cw) }

  # now construct all sequential phrases in the list and check for matches
  content_length.each do |x|
    ix = 0
    while ix < content_words.length - x
      # construct phrase of length x
      content_phrase = content_words[ix..ix+x].join(' ')
      # if that phrase has an exatch match, add it to the list
      if key_content.include?(content_phrase)
        key_words << content_phrase
      end
      ix += 1
    end
  end

  unless key_words.empty?
    words_code = key_words.join(', ')
    # make a new cell with same onset and offset as transcribe cell
    # also populate the words code
    ncell = english_mathwords.new_cell()
    ncell.onset = tcell.onset
    ncell.offset = tcell.offset
    ncell.words = words_code

    # see if there is already an existing corresponding category cell
    # in which case we do not want to overwrite it
    category_cell = english_categories.cells.select{ |c| c.onset == tcell.onset }
    # only make new cell if it's empty
    if category_cell.empty?
      # make corresponding cell for categories as well
      # for now, leave its codes blank
      ncell = english_categories.new_cell()
      ncell.onset = tcell.onset
      ncell.offset = tcell.offset
    end
  end

end

# reflect these changes in the DV spreadsheet
set_column('mathwords', english_mathwords)
set_column('mathcategories', english_categories)
