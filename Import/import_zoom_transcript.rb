## Before running this script: put all your zoom exported transcript .vtt files
## and/or .txt files into a folder on your desktop called zoom_transcript.
## Running this script will insert and populate a transcribe column in your
## currently open datavyu spreadsheet.

## This script imports time-stamped transcriptions exported from zoom video chats
## in the form of .vtt files (or .txt files) into the currently open datavyu
## spreadsheet.
## It will create a new column called transcript with codes <source> and
## <content> with a cell for each transcription.

## Parameters
# folder that contains the zoom .vtt files with transcripts
input_folder = '~/Desktop/zoom_transcript'
# name of column in which to import transcription data
transcript_col_name = 'transcribe'
# name of code with speaker id
speaker_id_code = 'source'
# name of code with actual transcription
transcript_code = 'content'

## Body
require 'Datavyu_API.rb'
# expand the path to include home directory
input_path = File.expand_path(input_folder)
# initialize arrays in which to store each transcription's onset, offset, source,
# and content
onset_list = []
offset_list = []
source_list = []
content_list = []
# get a list of all .vtt zoom transcript files
infiles = Dir.chdir(input_path){ Dir.glob('*.vtt') }
# add .txt files too
infiles << Dir.chdir(input_path){ Dir.glob('*.txt') }
infiles.flatten!

# now iterate over each .vtt/.txt file and populate arrays with onset, offset,
# source, and content
infiles.each do |infile|
  # open the current file
  file = File.open(File.join(input_path,infile))
  header = file.readline()
  # transcriptions are done in batches of 3 with one empty line between
  while true
    # empty line
    empty_line = file.readline()
    # break out of loop if you've reached the end of the file
    if file.eof?
      break
    end
    # contains ordinal
    ordinal_line = file.readline()
    # contains timestamps
    timestamp_line = file.readline()
    # contains source and content
    source_content_line = file.readline()

    # get characters denoting onset HH:MM:SS.mmm
    zoom_onset = timestamp_line[0..11]
    # get characters denoting onset HH:MM:SS.mmm
    zoom_offset = timestamp_line[17..-3]
    # parse hours, minutes, seconds, and milliseconds
    zoom_onset_HH = zoom_onset.split(':')[0]
    zoom_onset_MM = zoom_onset.split(':')[1]
    zoom_onset_SS = zoom_onset.split(':')[2].split('.')[0]
    zoom_onset_mmm = zoom_onset.split(':')[2].split('.')[1]
    # same for offset
    zoom_offset_HH = zoom_offset.split(':')[0]
    zoom_offset_MM = zoom_offset.split(':')[1]
    zoom_offset_SS = zoom_offset.split(':')[2].split('.')[0]
    zoom_offset_mmm = zoom_offset.split(':')[2].split('.')[1]
    # convert to absolute milliseconds for datavyu times
    dv_onset = zoom_onset_HH.to_i*60*60*1000 + zoom_onset_MM.to_i*60*1000 +
      zoom_onset_SS.to_i*1000 + zoom_onset_mmm.to_i
    dv_offset = zoom_offset_HH.to_i*60*60*1000 + zoom_offset_MM.to_i*60*1000 +
      zoom_offset_SS.to_i*1000 + zoom_offset_mmm.to_i
    onset_list << dv_onset
    offset_list << dv_offset

    # seems that some lines don't have a source preceeding the colon
    if source_content_line.split(':').length == 1
      source = ''
      content = source_content_line.split(':')[0][0..-3]
    else
      source = source_content_line.split(':')[0]
      content = source_content_line.split(':')[1][1..-3]
    end
    source_list << source
    content_list << content

  end
end

# initialize new column with codes for transcript
transcribe = new_column(transcript_col_name, [speaker_id_code, transcript_code])

# loop through onsets and create a cell for each
onset_list.each_with_index do |x,i|
  # create new cell
  ncell = transcribe.new_cell
  # populate onset, offset, source, and content codes
  ncell.onset = x
  ncell.offset = offset_list[i]
  ncell.change_code(speaker_id_code, source_list[i])
  ncell.change_code(transcript_code, content_list[i])
end
# reflect these changes in the datavyu spreadsheet
set_column(transcript_col_name, transcribe)
