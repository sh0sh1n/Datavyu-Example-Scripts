## Parameters
# add a new cell to voc_turns column every time a cell from transcribe_child
# starts within this time range after the start of a transcribe_mom cell; in turn
# add a new cell to voc_turns column every time a cell from transcribe_mom
# starts within this time range after the start of a transcribe_child cell.

# for ambiguous cases when mom & baby spoke at the same time, we counted as a
# turn taking sequence as long the mom or baby still responded within 3 sec as
# this does not negate fact that they engaged with turn-taking

#one things to figure out:
#1. Combine pairs of utterances into full turns if they overlap using a new tts col

#time_range = [0, 3000]
time_window = 3000

## Body
require 'Datavyu_API.rb'

begin

    # Get the transcription column
    transcribe = get_column('transcribe')

    # Create new column for instances of turn-taking
    turns = new_column('voc_turns','initiator','ender')

    # Loop over the transcribe column
    for i in 0..transcribe.cells.length-2
        curr_cell = transcribe.cells[i]
        next_cell = transcribe.cells[i+1]

        # Check if speaker changes between current cell & next cell, and it's within our time window
        if (curr_cell.source_mc != next_cell.source_mc) and ((next_cell.onset - curr_cell.onset) < time_window)

            new_cell = turns.new_cell # If our definition for turn-taking is met, insert a new cell in the turn-taking column
            new_cell.change_arg("onset",curr_cell.onset) # Onset = onset of the first speaker (aka onset of current cell)
            new_cell.change_arg("offset",next_cell.onset) # Offset = onset of second speaker (aka onset of next cell)
            new_cell.change_arg("initiator",curr_cell.source_mc) # First speaker (aka source in current cell) = the initiator
            new_cell.change_arg("ender",next_cell.source_mc) # Second speaker (aka source in the next cell) = the ender

        end
    end

    # Set the column back to the spreadsheet
    set_column('voc_turns', turns)

end
