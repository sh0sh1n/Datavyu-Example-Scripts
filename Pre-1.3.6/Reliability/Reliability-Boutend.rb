require 'Datavyu_API.rb'

# Params
pri_prefix = 'pri_'
rel_prefix = 'rel_'
begin
  dump_file = File.new(File.expand_path("~/Desktop/RelBoutend.txt"), 'w')
  checkReliability("boutend", "rel_boutend", "onset", 100, dump_file)
  boutend_codes = %w(destination)

  diss_codes = boutend_codes.map{ |x| [pri_prefix + x, rel_prefix + x] }.flatten
  diss_codes << "comments"
  boutend_diss = createColumn("boutend_diss", *(diss_codes))
  pri = getColumn("boutend")
  rel = getColumn("rel_boutend")
  pri_cells = pri.cells
  rel_cells = rel.cells

  for relcell in rel_cells
    pricell = pri_cells.find { |pricell| pricell.onset == relcell.onset}
    newcell = nil
    boutend_codes.each do |codename|
      pri_code = pricell.get_arg(codename)
      rel_code = relcell.get_arg(codename)
      if pri_code != rel_code
        newcell = boutend_diss.make_new_cell if newcell.nil?
        newcell.onset = pricell.onset
        newcell.offset = pricell.offset
        newcell.change_arg(pri_prefix + codename, pri_code)
        newcell.change_arg(rel_prefix + codename, rel_code)
      end
    end
  end
  setColumn(boutend_diss)
  setColumn('boutend_original', pri)
end
