#Inserting bouts for coding if baby has toy (for free play).

require "Datavyu_API.rb"

begin

toys = createColumn('toys', 'broom', 'redball', 'stroller', 'popper', 'tub', 'littleball', 'doll')
babymovement = getColumn('babymovement')

bmv_cells = babymovement.cells
toys_cells= toys.cells

bmv_cells.each do |bcell|
		ncell = toys.make_new_cell()
		ncell.onset = bcell.onset
		ncell.offset = bcell.offset
end

setColumn(toys)
end
