# Checks the onset/offset times of infant digiframes cells to make sure they are identical and
# makes sure that each of the digiframes cell is contained within a stepsDigi cell.
# Single spreadsheet version.

require 'Datavyu_API.rb'

begin
	verbose = 1
	errcount = 0
	warncount = 0

	# Fetch the stepsDigiB column.
	col_stepsDigiB = getVariable('stepsDigiB')

	# Fetch the digiframesBL and digiframesBR columns.
	col_digiframesBL = getVariable('digiframesBL')
	if col_digiframesBL.nil?
		puts "WARNING: No digiframesBL column found."
	elsif col_digiframesBL.cells.size > 0
		# Check left foot
		puts "Checking digiframesBL..." if verbose > 0
		times = []
		for stepcell in col_digiframesBL.cells
			# Check if onset matches offset
			if stepcell.onset != stepcell.offset
				error = "Cell #{stepcell.ordinal} : onset-offset mismatch "
				puts(error) if verbose > 0
				errcount += 1
			end

			# Check if contained by a cell in stepsDigiB (use onset time)
			if getCellFromTime(col_stepsDigiB,stepcell.onset).nil?
				error = "Cell #{stepcell.ordinal} : not part of bout cell."
				puts(error) if verbose > 0
				errcount += 1
			end

			# Check if onset time is a repitition
			if times.include?(stepcell.onset)
				error = "Cell #{stepcell.ordinal} : duplicate onset."
				puts error if verbose > 0
				errcount += 1
			end
			times << stepcell.onset
		end

		# Check to make sure every stepsDigiM cell has a digiframe cell
		col_stepsDigiB.cells.each do |x|
			if col_digiframesBL.cells.select{ |y| x.contains(y) }.size == 0
				puts "WARNING: stepsDigiB cell #{x.ordinal} has no digiframesBL cells"
				warncount += 1
			elsif col_digiframesBL.cells.find{ |y| x.onset == y.onset}.nil?
				puts "WARNING: stepsDigiB cell #{x.ordinal} has no digiframesBL cell at the beginning."
				warncount += 1
			end
		end

		puts if verbose > 0
	end

	# Fetch right foot cells
	col_digiframesBR = getVariable('digiframesBR')
	if col_digiframesBR.nil?
		puts "WARNING: No digiframesBR column found."
	elsif col_digiframesBR.cells.size > 0
		# Check right foot
		puts "Checking digiframesBR..." if verbose > 0
		times = []
		for stepcell in col_digiframesBR.cells
			# Check if onset matches offset
			if stepcell.onset != stepcell.offset
				error = "Cell #{stepcell.ordinal} : onset-offset mismatch "
				puts(error) if verbose > 0
				errcount += 1
			end

			# Check if contained by a cell in stepsDigiB (use onset time)
			if getCellFromTime(col_stepsDigiB,stepcell.onset).nil?
				error = "Cell #{stepcell.ordinal} : not part of bout cell."
				puts(error) if verbose > 0
				errcount += 1
			end

			# Check if onset time is a repitition
			if times.include?(stepcell.onset)
				error = "Cell #{stepcell.ordinal} : duplicate onset."
				puts error if verbose > 0
				errcount += 1
			end
			times << stepcell.onset
		end

		# Check to make sure every stepsDigiB cell has a digiframe cell
		col_stepsDigiB.cells.each do |x|
			if col_digiframesBR.cells.select{ |y| x.contains(y) }.size == 0
				puts "WARNING: stepsDigiB cell #{x.ordinal} has no digiframesBR cells"
				warncount += 1
			elsif col_digiframesBR.cells.find{ |y| x.onset == y.onset}.nil?
				puts "WARNING: stepsDigiB cell #{x.ordinal} has no digiframesBR cell at the beginning."
				warncount += 1
			end
		end

		puts if verbose > 0
	end

	# Check the stepsDigiB column to make sure no stray cells were added
	strayCells = col_stepsDigiB.cells.select{ |x| x.locomotion=="" || x.steps=="" }
	strayCells.each do |cell|
		error = "Stray cell found in stepsDigiB: Cell #{cell.ordinal} missing code"
		puts error if verbose > 0
		errcount += 1
	end

	# Check to make sure the left and right cells add up to number of steps (minus 2 for the beginning cells)
	unless(col_digiframesBL.nil? || col_digiframesBL.cells.empty? || col_digiframesBR.nil? || col_digiframesBR.cells.empty?)
		col_stepsDigiB.cells.each do |d|
			steps = d.steps.to_i
			cells = [col_digiframesBL, col_digiframesBR].map{ |col| col.cells.select{ |x| d.contains(x)}.size - 1 }.reduce(:+)
			unless steps == cells
				puts "WARNING: stepsDigiB cell #{d.ordinal} steps not equal to left and right cells. Expected #{steps}, found #{cells}."
				warncount += 1
			end
		end
	end

	puts if verbose > 0
	puts "Finished. Found #{errcount} error(s) and #{warncount} warning(s)" if verbose > 0
rescue StandardError => e
	puts e.message
	puts e.backtrace
end
