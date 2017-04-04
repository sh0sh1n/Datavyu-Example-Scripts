#Save orginal pri and rel babymovement columns
#Mutex babymovement and babymovement_rel columns
#Create bmovement_locomotion_dis, bmovement_possiblemomsupport_dis, and bmovement_steps_dis columns
#Check if onset and offsets of baby movement cells are within 170ms of each other
#Check for locomotion agreement
#Check for possiblemomsupport agreement
#Check for steps agreement
#Compute percent agreement
#TEST

require 'Datavyu_API.rb'

@placeholder_code = "-"
def getCode(cell,arg)
  val = cell.get_arg(arg)
  val = @placeholder_code if (val.nil? or val == "")
  return val
end

# Add some helper methods to RCell
class RCell
  # Return offset minus onset, as integer
  def duration
    return offset.to_i - onset.to_i
  end
end

begin
  # Parameters
  mutex_threshold = 170
  id_col_name = 'id'
  mutex_col_name = 'babymovementmutex'
  relblock_col_name = 'rel_blocks_babymovement'
  col_name = 'babymovement'
  rel_col_name = 'rel_babymovement'
  disagree_col_name = 'bmv_disagree'
  safe_mode = false
  verbose = 1

  #save orginal pri and rel babymovement columns
  babymovement = getColumn('babymovement')
  setColumn("babymovement_original", babymovement)
  rel_babymovement = getColumn('rel_babymovement')
  setColumn("rel_babymovement_original", rel_babymovement)

  # Open output file and write heading
  outdir = File.expand_path("~/Desktop")
  outfile = File.new(File.join(outdir,"BabyMovementRel.txt"),"w")
  outfile.puts("babymovement reliability\n")
  outfile.puts(['loc_pri','loc_rel','touch_pri','touch_rel','stp_pri','stp_rel'].join("\t"))

  # Fetch all column names
  columnNames = getVariableList()

  # Check to make sure the primary and reliability columns exist (and also id column)
  if not ([col_name,rel_col_name,id_col_name] - columnNames).empty?
    raise RuntimeError.new('File does not include necessary columns.')
  end

  # If safe_mode is on, don't overwrite mutex column if it exists
  if safe_mode and (columnNames&[mutex_col_name,disagree_col_name]).size > 0
    raise RuntimeError.new('Refused to overwrite existing columns.  Check column names or turn safe mode off.')
  end

  # Create mutex column
  mutex = create_mutually_exclusive(mutex_col_name,col_name,rel_col_name)
  puts("MUTEXED") if verbose > 0
  setVariable(mutex)
  puts("Finished MUTEX") if verbose > 0

  # Load columns
  id = getVariable("id")
  mutex = getVariable(mutex_col_name)
  relblocksmov = getVariable(relblock_col_name)
  col_pri = getVariable(col_name)
  col_rel = getVariable(rel_col_name)

  # Create the disagreements column
  bmv_disagree_new = createNewVariable(disagree_col_name,'loc_pri','loc_rel','touch_pri','touch_rel','stp_pri','stp_rel','comments')

  # Init counters for millisecond disagreements
  total = 0
  disagreement_loc = 0
  disagreement_mtouch = 0
  disagreement_stp = 0
  disagreement_adj = 0

  # Get total duration of relblocksmov cell
  total = relblocksmov.cells.map{ |x| x.duration}.reduce(:+)

  # Save some frequently accessed values
  my_subj = id.cells[0].subj

  # Build list of mutex cells that are within bounds of the rel blocks.
  candidateCells = []
  for relblock in relblocksmov.cells
    candidateCells += mutex.cells.select{ |x| relblock.contains(x) }
  end

  disagreement_raw = candidateCells.map{ |x| x.duration }.reduce(:+)

  # Build a set to store tuples of (onset,offset).  We need this to find cells with duration
  # less than mutex_threshold that have been entirely missed by one of the coders.
  myMap = (col_pri.cells + col_rel.cells).map{ |x| [x.onset.to_i,x.offset.to_i] }.uniq

  # From the candidate cells, filter out cells which are just onset or offset disagreements
  # with durations less than mutex_threshold.  Also filter out cells which only disagree on ordinals.
  for cell in candidateCells
    dur = cell.duration
    loc = cell.babymovement_locomotion
    rloc = cell.rel_babymovement_locomotion
    mtouch = cell.babymovement_possiblemomsupport
    rmtouch = cell.rel_babymovement_possiblemomsupport
    stp = cell.babymovement_steps
    rstp = cell.rel_babymovement_steps

    # Assign each check condition to a flag
    flagDur = dur >= mutex_threshold # disagreement is larger than or equal to threshold
    flagMissed = ([loc,mtouch,stp].all?{|x| x==""} or [rloc,rmtouch,rstp].all?{|y| y==""})  # (at least) one coder hasn't coded this region
    flagWholeCell= myMap.include?([cell.onset.to_i,cell.offset.to_i])  # this region is an entire pri or rel cell
    flagLoc = (loc != rloc) # locomotion code differs
    flagTouch = (mtouch =='n' && mtouch != rmtouch) # possiblemomsupport code differs
    flagStp = (stp != rstp) # steps code differs
    flagCodeDiffers = (not flagMissed and (flagLoc or flagTouch or flagStp)) # coders coded different values
    flagOnsetOffsetDisagree = (flagMissed and flagDur)  # one coder didn't code region
    flagMissedWhole = (flagWholeCell and flagMissed)

    # Assemble the overall filter from the flags
    # Either the cell was completely missed or there is a code disagreement or there is a large difference in onset/offset
    flagDisagreement = (flagMissedWhole or flagCodeDiffers or flagOnsetOffsetDisagree)

    # If the cell has matched our filters, add it to disagreement column
    if flagDisagreement
      disagreement_adj += dur
      ncell = bmv_disagree_new.make_new_cell()
      ncell.change_arg('onset',cell.onset)
      ncell.change_arg('offset',cell.offset)
      ncell.change_arg('loc_pri',getCode(cell,'babymovement_locomotion'))
      ncell.change_arg('loc_rel',getCode(cell,'rel_babymovement_locomotion'))
      ncell.change_arg('touch_pri',getCode(cell,'babymovement_possiblemomsupport'))
      ncell.change_arg('touch_rel',getCode(cell,'rel_babymovement_possiblemomsupport'))
      ncell.change_arg('stp_pri',getCode(cell,'babymovement_steps'))
      ncell.change_arg('stp_rel',getCode(cell,'rel_babymovement_steps'))

      outfile.puts(ncell.argvals.join("\t"))
    end

    # Add to counters if conditions met
    disagreement_loc+=dur if flagLoc
    disagreement_mtouch+=dur if flagTouch
    disagreement_stp+=dur if flagStp
    #disagreement_stp+=(cell.babymovement_steps.to_i-cell.rel_babymovement_steps.to_i).abs if flagStp
  end

  # Set the variable
  setVariable(bmv_disagree_new)

  # Calculate agreement percentages
  disagreements = [disagreement_loc,disagreement_mtouch,disagreement_stp,disagreement_raw, disagreement_adj]
  agreementPercents = []
  for x in disagreements
    agreementPercents << (100 * (1 - (x.to_f/total.to_f)))
  end
  strLocAgree = "Locomotion agreement: #{agreementPercents[0]}%"
  strMTAgree = "possiblemomsupport agreement: #{agreementPercents[1]}%"
  strStepsAgree = "Steps agreement: #{agreementPercents[2]}%"
  strRawAgree = "Total raw agreement: #{agreementPercents[3]}%"
  strAdjAgree = "Total adjusted agreement: #{agreementPercents[4]}%"
  outstr = [strLocAgree,strMTAgree,strStepsAgree,strRawAgree,strAdjAgree].join("\n")

  puts outstr if verbose > 0
  outfile.puts(outstr)

  puts("Finished.")
end
