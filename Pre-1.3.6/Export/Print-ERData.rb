## Parameters
# Directory containing Datavyu files
datavyu_dir = "~/Desktop/Datavyu"

# Full path of output file
output_path = '~/Desktop/ER_DATA.csv'

# Separator string
delimiter = ','

# Print header in output file
print_header = true

# Hashmap from column names to the array of argument names to print
# NOTE: %w(a b c) is same as ["a", "b", "c"]
code_map = {
	'session' => %w(ordinal),
  'floortime' => %w(ordinal),
  'babymovement' => %w(ordinal locomotion possiblemomsupport steps),
  'toys' => %w(ordinal broom redball stroller popper tub littleball doll),
  'bout_metrics' => %w(ordinal distance displacement explored cumul_explored sepdistend),
  'subject_metrics' => %w(ordinal distance displacement explored),
	'mb_separation_stats' => %w(ordinal overall_lt50 overall_lt100 overall_min overall_max overall_mean),
	'boutend' => %w(ordinal destination)

}
columns_to_merge = code_map.keys
id_codes = %w(study subj agemo sex bdate tdate bweight bheight brtleg bltleg bhead bweightpercent bheightpercent bweightforheightpercent crawlwalk walkdate cruisedate hkdate bellydate falls condition)

## Body
require 'Datavyu_API.rb'

# Merge arguments and cells in columns, similar to how create_mutually_exclusive works.
def merge_columns(name,*cols)
	debug = false
	if cols.nil? or cols.size<2
		return cols.first
	end

	# Concatenate arglists and cells.
	myArgs = []
	allcells = []
	cols.each{
		|x|
		myArgs << x.name.downcase+"_ordinal"
		myArgs << x.arglist.map{ |y| x.name.downcase+"_"+y}
		allcells << x.cells
	}
	myArgs.flatten!
	allcells.flatten!
	puts myArgs if debug
	puts allcells if debug

	myCol = createNewVariable(name,*myArgs)
	puts myCol.inspect if debug

	# Gather onsets and offsets and collect unique times into a single array
	onsets = allcells.map{|x| x.onset.to_i}
	offsets = allcells.map{|x| x.offset.to_i}
	times = (onsets+offsets).uniq.sort

	puts times if debug


	# For each consecutive time in times, create a new cell over that interval.
	if times.size>0
		onset = times.first
		for offset in times[1..-1]
			ncell = myCol.make_new_cell()
			ncell.onset = onset
			ncell.offset = offset

			ocells = cols.map{
				|x|
				x.cells.find{
					|y|
					y.contains(ncell) or y.onset==ncell.onset
				}
			}

			for c in ocells
				if not c.nil?
					ncell.change_arg(c.parent.downcase+"_ordinal", c.ordinal)
					c.arglist.each{
						|a|
						ncell.change_arg(c.parent.downcase+"_"+a,c.get_arg(a))
					}
				end
			end
			onset = offset
		end
	end

	return myCol
end

# Get arglist codes as an array from the cell.
# If arglist not specified, returns all args by calling cell.argvals
# Special arguments are : ordinal, onset, offset
def get_codes(cell,arglist=nil)
	argvals = []
	if arglist.nil?
		arglist = cell.arglist
	end

	arglist.each{
		|x|
		case x
		when 'ordinal'
			arg = cell.ordinal
		when 'onset'
			arg = cell.onset
		when 'offset'
			arg = cell.offset
		else
			begin
				arg = cell.get_arg(x)
			rescue	# if code doesn't exist
				puts "WARNING: No argument found for #{x}.  Using default."
				arg = '.'
			end
		end
		argvals<< arg
	}

	return argvals
end

begin
	# Get files from input folder
	datavyu_path = File.expand_path(datavyu_dir)
	input_files = Dir.chdir(datavyu_path){ Dir.glob('*.opf') }

	data = [] # Init array to store rows of data

	# Generate the list of code names from code_map
	code_names = ['onset', 'offset']
	code_map.each_pair{ |col, codes| codes.map{ |x| code_names << "#{col}_#{x}"} }

	# Add header if param set
	if print_header
		data << (id_codes + code_names).join(delimiter)
	end

	input_files.each do |infile|
    puts "Working on #{infile}"
		$db, $proj = load_db(File.join(datavyu_path, infile))	# load spreadsheet
		id_cell = getVariable('id').cells.first
		id_data = get_codes(id_cell, id_codes)
		columns = {}
		# load columns
		code_map.each do |k, v|
			c = getVariable(k)
			c = createVariable(k, *v) if c.nil? # make blank column if it doesn't exist
			columns[k] = c
		end

		cols2merge = columns_to_merge.map{ |x| columns[x] }
		merge_col = merge_columns('merge_export', *(columns_to_merge.map{ |x| columns[x] }))

		row = []
		merge_col.cells.each do |cell|
			row = id_data + get_codes(cell, code_names)
			data << row.join(delimiter)
		end
	end

	# Write data to output file
	output_path = File.expand_path(output_path)
	outfile = File.open(output_path, 'w')
	outfile.puts(data)
	outfile.close
end
