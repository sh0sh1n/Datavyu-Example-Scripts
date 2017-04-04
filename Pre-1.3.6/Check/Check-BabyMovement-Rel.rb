# Typo script for baby movement primary column.

require 'Datavyu_API.rb'

# Returns if the regex does not match arg
def checkTypo(arg,regex)
  return !(arg=~regex)
end

begin
  # Params
  w_cell_thresh = 500 # minimum number of ms between consecutive walk cells
  # Valid codes regexs
  valid_locomotion_codes =   /[wchbf\.]/
  valid_steps_codes = /(\.)|(\A\d+\Z)/
  valid_momsupp_codes = /[ynm]/

  mv = getVariable('rel_babymovement')
  session = getVariable('session')

  prevcell = nil # reference to previous cell

  # Loop over all movement cells
  mv.cells.each do |mvcell|
    ordinal = mvcell.ordinal.to_i
    onset = mvcell.onset.to_i
    offset = mvcell.offset.to_i

    # Check if onset is greater than offset
    if onset >= offset
      puts("CELL #{ordinal} ONSET >= OFFSET")
    end

    # Check to make sure the duration is at least one frame
    if offset-onset<34
      puts("CELL #{ordinal} DURATION < 1 FRAME")
    end

    # Check if locomotion code is a valid code
    if !(mvcell.locomotion =~ valid_locomotion_codes)
      puts("TYPO #{ordinal} LOCOMOTION CODED AS #{mvcell.locomotion}")
    end

    # Check if steps code is a valid code
    if !(mvcell.steps =~ valid_steps_codes)
      puts("TYPO #{ordinal} STEPS CODED AS #{mvcell.steps}")
    end

    # Check if momsupport code is a valid code
    if !(mvcell.possiblemomsupport =~ valid_momsupp_codes)
      puts("TYPO #{ordinal} POSSIBLEMOMSUPPORT CODED AS #{mvcell.possiblemomsupport}")
    end

    # This check identifies consecutive walk cells that are less than w_cell_thresh apart
    if (!prevcell.nil? &&
      prevcell.locomotion==mvcell.locomotion &&
      prevcell.possiblemomsupport==mvcell.possiblemomsupport &&
      (mvcell.onset-prevcell.offset).abs<w_cell_thresh )

      puts("CELLS #{prevcell.ordinal} and #{mvcell.ordinal} are walking bouts with less than #{w_cell_thresh}ms interval")
    end

    #Check to make sure there is an encolsing session cell for each movement cell
    if (session.cells.select{|session_cell| session_cell.contains(mvcell)}.empty?)
      puts "CELL #{mvcell.ordinal} is not bounded by a session cell"
    end
    prevcell = mvcell
  end

  puts("TYPOS CHECKED")
end
