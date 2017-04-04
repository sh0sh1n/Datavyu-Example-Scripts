require 'Datavyu_API.rb'
# Sorts cells in order of ascending duration

begin
  col_boutend = getVariable("boutend")
  rel_boutend = createNewVariable("rel_boutend", "destination")

  #figure out how many rel trials to code 1/5 of trials
  relnum = col_boutend.cells.length / 4

  #shuffle all trials
  shuffled = col_boutend.cells.shuffle

  #select first relnum trials from shuffled array to get relnum randomly selected trials
  alltrials = shuffled[0..relnum-1]

  #insert rel cell for each random trial, carry over onset and trialnum
  for trials in alltrials
    relcell = rel_boutend.make_new_cell
    relcell.change_arg("onset", trials.onset)
    relcell.change_arg("offset", trials.offset)
    relcell.change_arg("ordinal", trials.ordinal)
  end

  #sort rel cells so they display properly
  rel_boutend.sort_cells

  setVariable("rel_boutend", rel_boutend)

end
