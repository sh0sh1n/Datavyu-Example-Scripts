# Search a column and display results
# Optionally, copy cells to a search column.

## Parameters
column_to_search = 'transcribe'
code_to_search = 'content'
search_expression = %w(see) # find this word or pattern
result_column = 'search_result' # copy the result cells to this column; set to nil or '' to suppress this behavior
select_criteria = ->(cell){ cell.speaker == 'm' } # search only cells with speaker code equal to 'm'

## Body
require 'Datavyu_API.rb'

scol = get_column(column_to_search)
results = []

# Apply selection criteria if specified
unless select_criteria.nil? || select_criteria == ''
  scells = scol.cells.select &select_criteria
else
  scells = col.cells
end

scells.select do |cell|
  code = cell.get_code(code_to_search)
  case search_expression
  when Array
    results << cell if search_expression.any?{ |v| code.split(' ').include?(v) }
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
