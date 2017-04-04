# Insert column to code no reaching trials

require 'Datavyu_API.rb'

reach = getColumn('Reach')
reachCells = reach.cells

validCells = reachCells.select do |x|
  (x.reachhand == 'n')
end


# Create new column for omnidirection
noreaching = createColumn("NoReach", 'handmov')

for cell in validCells
  noreachcell = noreaching.make_new_cell
  noreachcell.onset = cell.onset
  noreachcell.offset = cell.offset
end

 setColumn(noreaching)
