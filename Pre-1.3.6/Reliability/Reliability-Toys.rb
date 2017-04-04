require 'Datavyu_API.rb'

# Params
pri_prefix = 'pri_'
rel_prefix = 'rel_'
begin
  dump_file = File.new(File.expand_path("~/Desktop/RelToys.txt"), 'w')
  checkReliability("toys", "rel_toys", "onset", 100, dump_file)
  toy_codes = %w(broom redball stroller popper tub littleball doll)

  diss_codes = toy_codes.map{ |x| [pri_prefix + x, rel_prefix + x] }.flatten
  diss_codes << "comments"
  toys_diss = createColumn("toys_diss", *(diss_codes))
  pri = getColumn("toys")
  rel = getColumn("rel_toys")
  pri_cells = pri.cells
  rel_cells = rel.cells

  for relcell in rel_cells
    pricell = pri_cells.find { |pricell| pricell.onset == relcell.onset}
    newcell = nil
    toy_codes.each do |codename|
      pri_code = pricell.get_arg(codename)
      puts pri_code
      puts
      rel_code = relcell.get_arg(codename)
      if pri_code != rel_code
        newcell = toys_diss.make_new_cell if newcell.nil?
        newcell.onset = pricell.onset
        newcell.offset = pricell.offset
        newcell.change_arg(pri_prefix + codename, pri_code)
        newcell.change_arg(rel_prefix + codename, rel_code)
      end
    end
  end
  setColumn(toys_diss)
  setColumn('toys_original', pri)
end
