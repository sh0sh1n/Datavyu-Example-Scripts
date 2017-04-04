# Transfer columns. Overwrite segments of columns.

source_file = '~/Desktop/Source.opf'
dest_file = '~/Desktop/Dest.opf'

require '~/scriptrepo/datavyu_api.rb'

set_column('babymovement_backup', get_column('babymovement'))
set_column('rel_block_babymovement_backup', get_column('rel_blocks_babymovement'))


transfer_columns(source_file, '', false, 'babymovement', 'rel_blocks_babymovement')

col_mvt_src = get_column('babymovement')
col_blocks_src = get_column('rel_blocks_babymovement')

cells2transfer = col_mvt_src.cells.select{ |x| col_blocks_src.cells.any?{ |y| y.contains(x)} }

col_mvt = get_column('babymovement_backup')
col_mvt.cells.select{ |x| col_blocks_src.cells.any?{ |y| y.contains(x) } }.each{ |z| delete_cell(z) }

cells2transfer.each{ |x| col_mvt.new_cell(x) }

set_column(col_mvt)
