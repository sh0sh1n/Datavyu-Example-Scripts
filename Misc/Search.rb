# Search a column and display results
# Optionally, copy cells to a search column.

## Parameters
column_to_search = 'mom_speech'
code_to_search = 'transcript'
search_expression = %w(apple ball slinky)
result_column = 'search_result'

## Body
require 'Datavyu_API.rb'

scol = get_column(column_to_search)
results = []
scells = scol.cells.select do |cell|
  code = cell.get_code(code_to_search)
  case search_expression
  when Array
    results << cell if search_expression.any?{ |v| code.include?(v) }
  when Regexp
    results << cell unless search_expression.match(code).nil?
  else
    raise "Can't search with expression type: #{search_expression.class}"
  end
end

res_col = new_column(result_column, *scol.arglist) unless result_column.nil? || result_column == ''

results.each do |cell|
  puts "Cell #{cell.ordinal}: #{cell.get_code(code_to_search)}"
  res_col.new_cell(cell) unless res_col.nil?
end

set_column(res_col) unless res_col.nil?
