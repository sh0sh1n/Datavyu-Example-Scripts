# Compute kappa score for ----- coding.

## Parameters
primary_column_name = 'momutterancetype'
reliability_column_name = 'momutterancetype_rel'

## Body
require 'Datavyu_API.rb'

def contingency_table(pri_values, rel_values)
  pri_values.flatten!
  rel_values.flatten!
  return [nil, {}] if pri_values.empty? || rel_values.empty?

  # Build a hashmap from the list of codes to all observed values for that code
  # across primary and reliability cells.
  observed_values = (pri_values + rel_values).uniq

  # Init contingency tables for each code name
  table = CTable.new(*observed_values)

  # Fill the contingency table.
  pri_values.zip(rel_values).each do |pv, rv|
    table.add(pv, rv)
  end
  table
end

pri_col = get_column(primary_column_name)
rel_col = get_column(reliability_column_name)

p_vals = []
r_vals = []
pri_col.cells.each do |p_cell|
  r_cell = rel_col.cells.select{ |c| c.onset == p_cell.onset }.first
  # skip if no matching rel cell
  next if r_cell.nil?
  pri_args = p_cell.get_codes(p_cell.arglist)
  rel_args = r_cell.get_codes(r_cell.arglist)
  # take the first argument that's not a period (args are mutually exlcusive)
  p_vals << pri_args.select{ |a| a unless a=='.' }.first
  r_vals << rel_args.select{ |a| a unless a=='.' }.first
end

t =  contingency_table(p_vals, r_vals)
printf("Kappa score:\t%.2f\n", t.kappa)
puts t
