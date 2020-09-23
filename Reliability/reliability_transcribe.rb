
## Parameters

## Assumes a primary and reliability coder have each coded transcriptions
## including their onsets and offsets.

# names of primary and reliablity transcription columns
# assumes these columns each have a code called content in which the transcription
# is coded
pri_col_name = 'transcribe'
rel_col_name = 'transcribe_R2'

# To find matching rel cell for given pri, script looks +/- time_tolerance ms
# relative to onset of pri cell. will take the rel cell whose onset is closest
# if no rel cell is found, will create a disagreement
time_tolerance = 500

## This script checks reliability on transcriptions by printing the % of instances
# where transcriptions matched exactly between pri and rel coders.
# Because the above criterion is so harsh, also prints average % of unique words
# in pri transcription that rel also contained across all instances
# Prints time-weighted average as well (longer transcriptions contribute more)

## Body
require 'Datavyu_API.rb'

# fetch the columns from the spreadsheet
transcribe = get_column(pri_col_name)
transcribe_rel = get_column(rel_col_name)

# make any cells with negative duration point cells (i.e. set offset=onset)
transcribe.cells.each do |tcell|
  if tcell.duration < 0
    tcell.change_code('offset',tcell.get_code("onset"))
  end
end
set_column('transcribe',transcribe)

transcribe_rel.cells.each do |tcell|
  if tcell.duration < 0
    tcell.change_code('offset',tcell.get_code("onset"))
  end
end
set_column('transcribe_R2',transcribe_rel)

# initialize a column to store transcribe disagreements
transcribe_disagree = new_column('transcribe_disagree',
  %w[pri_ordinal rel_ordinal pri_content rel_content comment])

# initialize array to store exact matches for each pri cell
exact_match = []
# initialize array to store % word agreement for each pri cell
percent_word = []

# loop through primary transcribe cells
transcribe.cells.each do |tcell|

  # get ordinal and onset of primary coder's cell
  pri_ordinal = tcell.ordinal
  pri_onset = tcell.onset

  # get distance in time of onsets of all rel cells
  rel_dist = transcribe_rel.cells.map { |t| (pri_onset-t.onset).abs }
  # take the rel cell closest in time to onset of primary cell
  if rel_dist.min <= time_tolerance
    # add one because ordinals start at 1 and indexing at 0
    rel_ordinal = rel_dist.index(rel_dist.min)+1
    tcell_rel =  transcribe_rel.cells.select { |t| t.ordinal==rel_ordinal }
    content_rel = tcell_rel.first.content
  else
    rel_ordinal = nil
    content_rel = ''
  end

  # get content for pri coder
  content = tcell.content

  # check for exact match in transcription
  # this will only return true if pri and code transcribed identically
  exact_match << (content == content_rel)

  # create cell in disagree column if the content does not exactly match
  unless content == content_rel
    ncell = transcribe_disagree.new_cell()
    ncell.onset = tcell.onset
    ncell.offset = tcell.offset
    # store pri and rel ordinals so user knows which cells are being compared
    ncell.pri_ordinal = pri_ordinal
    ncell.rel_ordinal = rel_ordinal
    ncell.pri_content = tcell.content
    ncell.rel_content = content_rel
    ncell.comment = ''
  end

  # get % of words that exactly match
  words = content.split(' ')
  words_rel = content_rel.split(' ')

  count = 0.0
  words.each do |w|
    if words_rel.include?(w)
      count += 1
    end
  end
  percent_word << count/words.length

end

# get array of duration of each pri cell
pri_dur = transcribe.cells.map { |tcell| tcell.duration }
# num pri cells
num_pri = pri_dur.length

num_match = exact_match.select { |e| e==true }.length
percent_exact_match = (100.0*num_match.to_f/num_pri).round(2)

total_dur = 0.0
pri_dur.each do |pdur|
  total_dur += pdur
end

match_dur = 0.0
count = 0
pri_dur.each do |pdur|
  if exact_match[count]==true
    match_dur += pdur
  end
  count += 1
end
# time weighted percent match (% of frames where exact match)
time_percent_exact_match = (100.0*match_dur/total_dur).round(2)

# get average word % agreement
count = 0
sum_percent = 0.0
sum_weighted_percent = 0.0
percent_word.each do |p|
  unless p.nil?
    sum_percent += p
    sum_weighted_percent += (pri_dur[count]/total_dur)*p
  end
  count += 1
end

ave_percent = 100.0*(sum_percent/num_pri.to_f).round(2)
weighted_percent = (100.0*sum_weighted_percent).round(2)

puts "Of the #{num_pri} cells coded by primary coder in column transcribe,
#{percent_exact_match}% have an exact content match with rel. This accounts for
#{time_percent_exact_match}% of the total duration coded by primary coder."

puts "\n"

puts "Of the #{num_pri} cells coded by primary coder in column transcribe,
the average percent word match is #{ave_percent}%. The time-weighted percent
word match is #{weighted_percent}%"

# reflect changes in DV spreadsheet
set_column('transcribe_disagree', transcribe_disagree)
