#Inserting bouts for coding where baby ends a bout (for free play).

require "Datavyu_API.rb"

begin

boutend = createColumn('boutend', 'destination')
babymovement = getColumn('babymovement')
floortime = getColumn('floortime')

floor_cells = floortime.cells
bmv_cells = babymovement.cells
boutend_cells= boutend.cells

floor_cells.each do |floorcell|
	bmv_cells.select{ |movementcell| movementcell.locomotion != 'f' && movementcell.onset >= floorcell.onset && movementcell.onset <= floorcell.offset }.each do |bcell|
		ncell = boutend.make_new_cell()
		ncell.onset = bcell.onset
		ncell.offset = bcell.offset
	end
end

setColumn(boutend)
end
