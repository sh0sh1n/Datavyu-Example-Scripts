#Inserting rel blocks for baby movement (for free play).

require "Datavyu_API.rb"

class RCell
	def duration
		return self.offset.to_i - self.onset.to_i
	end
end

begin
	session_column_name = 'session'
	block_column_name = "rel_blocks_babymovement"
	fraction = 0.25	# fraction of the session cell to use for each block cell

	sesion_column = getVariable(session_column_name)
	if sesion_column.nil?
		puts "Error : no column named #{session_column_name}"
		return
	end

	session_cells = sesion_column.cells
	# Check to make sure we have a reference cell
	if session_cells.length == 0
		puts "No valid reference cell!"
		return
	end


	block_column = createVariable(block_column_name,'arg')

	session_cells.each do |session_cell|
		new_cell = block_column.make_new_cell
		new_cell_duration = fraction*session_cell.duration
		new_cell.onset = rand(session_cell.duration - new_cell_duration)+session_cell.onset
		new_cell.offset = new_cell.onset+new_cell_duration
	end

	setColumn(block_column)
	rel_babymovement = createColumn('rel_babymovement', 'locomotion', 'possiblemomsupport', 'steps')
	setColumn(rel_babymovement)
end
