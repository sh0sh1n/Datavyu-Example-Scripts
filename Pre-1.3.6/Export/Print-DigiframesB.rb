# Print the onset times from the point cells in digiframesBL and digiframesBR columns.
# Also print the bout ordinal that contains that frame.
# In addition, convert the code in the digiframes cells to 'p'. If the codes in the cells
# are any special values, apply the appropriate operation to make any existing data files
# consistent (digitized CSV files from DLTdv5 Matlab tool).
# Runs on open spreadsheet.

## Params
output_folder = '~/Desktop'
data_folder = '~/Desktop/Data'

## Body
require 'Datavyu_API.rb'
require 'csv'

begin
	outdir = File.expand_path(output_folder)
	file = $db::getName() # get current Datavyu file's name

	# Check filename to make sure it is correct study.
	unless file.include?("EmptyRoom")
		raise "Unexpected file name: #{file}. Expected name to contain EmptyRoom."
	end

	# Fetch the stepsDigiB column.
	col_stepsDigiB = getVariable('stepsDigiB')

	col_digiframesBL = getVariable('digiframesBL')
	unless col_digiframesBL.nil?
		puts "Checking digiframesBL..."
		inserts = 0
		deletes = 0
		data_folder = File.expand_path(data_folder)
		Dir.chdir(data_folder) do |dir|
			left_data_files = Dir.glob( File.join('**', File.basename(file, '.opf') + '_bldigi*.csv') )
			break if left_data_files.empty?
			left_data = {}#Hash.new{ |h, k| h[k] = [] }
			left_data_files.each{ |f| left_data[f] = CSV.readlines(f) }

			change_cells = col_digiframesBL.cells.select{ |x| x.on != '' && x.on != 'p' }
			break if change_cells.empty?

			# Raise error if number of rows don't match number of unchanged cells.
			data_cells = col_digiframesBL.cells.reject{ |x| x.on == 'i' } # data should match up with cells that have not been marked as newly inserted
			raise "ERROR: existing data does not match spreadsheet. Found #{data_cells.size} cells and #{left_data.values.first.size - 1} digitized points." if data_cells.size != left_data.values.first.size-1
			data_cells.sort!{ |x, y| x.onset <=> y.onset }

			# Iterate over cells and transform existing data based on code.
			cells2delete = []
			change_cells.each do |c|
				case(c.on)
				when 'd'
					idx = data_cells.index{ |x| x.onset == c.onset }
					data_cells.delete_at(idx)
					left_data.values.each{ |d| d.delete_at(idx+1) } # data contains header, so add 1 to idx
					cells2delete << c
					deletes += 1
				when 'i'
					idx = data_cells.index{ |x| x.onset > c.onset } # first cell with onset greater than inserted cell
					data_cells.insert(idx, c)
					left_data.values.each{ |d| d.insert(idx+1, d.last) } # copy the last data row
					inserts += 1
				else
					raise "I don't know what to do with this code in cell #{c.ordinal}: #{c.on}"
				end
			end

			if(inserts+deletes > 0)
				cells2delete.each{ |x| delete_cell(x) } # delete the cells using delete_cell...just setting the column's cells to data_cells doesn't seem to work
				col_digiframesBL.cells = data_cells
				set_column(col_digiframesBL)
				col_digiframesBL = get_column('digiframesBL')

				if(inserts > 0)
					puts "Please digitize the following frames: " + col_digiframesBL.cells.select{ |x| x.on == 'i' }.map(&:ordinal).join(',')
				end
				# Print the transformed data files
				left_data.each_pair do |k, v|
					raise "#{k} data inconsistent: #{v.size-1}, expected #{data_cells.size}" unless v.size-1 == data_cells.size
					CSV.open(k, 'w+'){ |writer| v.each { |l| writer << l } }
				end
				puts "Reprinted data files. Made #{inserts} insertion(s) and #{deletes} deletion(s)."
			end
		end

		outfileL = File.open(File.join(outdir, File.basename(file, '.opf') + '_blframetimes.csv'),'w')
		# Loop over cells and print onset times and bout ordinals
		# No need to sort cells because they were sorted by onset by the getVariable() call
		col_stepsDigiB.cells.each do |boutcell|
			col_digiframesBL.cells.select{|x| boutcell.contains(x)}.each do |stepcell|
				stepcell.on = 'p'
				outfileL.puts [stepcell.onset,boutcell.ordinal].join(',')
			end
		end
		outfileL.close
		set_column(col_digiframesBL)
	end

	col_digiframesBR = getVariable('digiframesBR')
	unless col_digiframesBR.nil?
		puts "Checking digiframesBR..."
		inserts = 0
		deletes = 0
		Dir.chdir(data_folder) do |dir|
			right_data_files = Dir.glob( File.join('**', File.basename(file, '.opf') + '_brdigi*.csv') )
			break if right_data_files.empty?

			right_data = {}#Hash.new{ |h, k| h[k] = [] }
			right_data_files.each{ |f| right_data[f] = CSV.readlines(f) }

			change_cells = col_digiframesBR.cells.select{ |x| x.on != '' && x.on != 'p' }
			break if change_cells.empty?

			# Raise error if number of rows don't match number of unchanged cells.
			data_cells = col_digiframesBR.cells.reject{ |x| x.on == 'i' } # data should match up with cells that have not been marked as newly inserted
			raise "ERROR: existing data does not match spreadsheet. Found #{data_cells.size} cells and #{right_data.values.first.size - 1} digitized points." if data_cells.size != right_data.values.first.size-1
			data_cells.sort!{ |x, y| x.onset <=> y.onset }

			# Iterate over cells and transform existing data based on code.
			cells2delete = []
			change_cells.each do |c|
				case(c.on)
				when 'd'
					idx = data_cells.index{ |x| x.onset == c.onset }
					data_cells.delete_at(idx)
					right_data.values.each{ |d| d.delete_at(idx+1) } # data contains header, so add 1 to idx
					cells2delete << c
					deletes += 1
				when 'i'
					idx = data_cells.index{ |x| x.onset > c.onset } # first cell with onset greater than inserted cell
					data_cells.insert(idx, c)
					right_data.values.each{ |d| d.insert(idx+1, d.last) } # copy the last data row
					inserts += 1
				else
					raise "I don't know what to do with this code in cell #{c.ordinal}: #{c.on}"
				end
			end

			if(inserts+deletes > 0)
				cells2delete.each{ |x| delete_cell(x) } # delete the cells using delete_cell...just setting the column's cells to data_cells doesn't seem to work
				col_digiframesBR.cells = data_cells
				set_column(col_digiframesBR)
				col_digiframesBR = get_column('digiframesBR')

				if(inserts > 0)
					puts "Please digitize the following frames: " + col_digiframesBR.cells.select{ |x| x.on == 'i' }.map(&:ordinal).join(',')
				end
				# Print the transformed data files
				right_data.each_pair do |k, v|
					raise "#{k} data inconsistent: #{v.size-1}, expected #{data_cells.size}" unless v.size-1 == data_cells.size
					CSV.open(File.join(outdir, File.basename(k)), 'w+'){ |writer| v.each { |l| writer << l } }
				end
				puts "Reprinted data files. Made #{inserts} inserts and #{deletes} deletions."
			end
		end

		outfileR = File.open(File.join(outdir, File.basename(file, '.opf') + '_brframetimes.csv'), 'w')

		col_stepsDigiB.cells.each do |boutcell|
			col_digiframesBR.cells.select{ |x| boutcell.contains(x) }.each do |stepcell|
				stepcell.on = 'p'
				outfileR.puts [stepcell.onset, boutcell.ordinal].join(',')
			end
		end
		outfileR.close
		set_column(col_digiframesBR)
	end

	puts "Finished."
rescue StandardError => e
	puts e.message
	puts e.backtrace
ensure
	outfileL.close unless outfileL.nil? or outfileL.closed?
	outfileR.close unless outfileR.nil? or outfileR.closed?
end
