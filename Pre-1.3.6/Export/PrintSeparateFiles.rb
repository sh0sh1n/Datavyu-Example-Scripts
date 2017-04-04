# Print cells from 'reach and eye' columns in DRETS Datavyu files

require 'Datavyu_API.rb'

dvyudir = '~/Desktop/Export'
outdir = '~/Desktop/'

# Fetch Datavyu files
dvyufiles = get_datavyu_files_from(dvyudir)

for file in dvyufiles
	puts "Working on : #{file}"

	# Create the output file.
	outfile = File.open(File.join(outdir,File.basename(file,'.opf')+'_DatavyuOutput.csv'),'w')

	# Output header
	outfile.puts "study,subjectNum,age,gender,hand-dominanceblock,block,trial,trialOnset,trialOffset,chairdir,degrees,reachOnset,reachOffset,reachHand,miss-grasp,objInView,fixOnset,fixation"

	#load database from file
	$db,$proj = loadDB(File.join(dvyudir,file))

	# Fetch the columns.  Skip this file if no such column exists.
	col_id = getVariable('ID')
	col_block = getVariable('Block')
	col_trial = getVariable('Trial')
	col_reach = getVariable('Reach')

	col_eye = getVariable('Eye')

	idcell = col_id.cells.first
	idcodes = [idcell.study, idcell.s, idcell.age, idcell.sex, idcell.handdominance]

	# Loop over reach cells.  Find the corresponding rel_reach, eye, and rel_eye cells for each reach cell.
	# For each reach cell 'r', rel_reach cells will have the same onset as 'r', eye cell and rel eye cell will have 'trialnum' code that is the same as the ordinal of 'r'
	reachCells = col_reach.cells
	eyeCells = col_eye.cells
	for blockcell in col_block.cells
		for trialcell in col_trial.cells.select{|x| x.is_within(blockcell)}
	  	# Find the matching rel cell.  If one does not exist, use placeholder values
			reachcell = reachCells.find{ |x| x.ordinal==trialcell.ordinal}
	  	eyecell = eyeCells.find{ |x| x.ordinal==trialcell.ordinal }
			blockcodes = [blockcell.condition]
			trialcodes = [trialcell.ordinal, trialcell.onset, trialcell.offset, trialcell.chairdir, trialcell.degrees]
    	reachcodes = [reachcell.onset,reachcell.offset,reachcell.hand,reachcell.missgrasp]
    	eyecodes = [eyecell.onset,eyecell.offset,eyecell.fix]
    	allcodes = idcodes + blockcodes + trialcodes + reachcodes + eyecodes
			outfile.puts allcodes.join(',')
		end
	end

	# Close the output file.
	outfile.close()
end
puts "Finished."
