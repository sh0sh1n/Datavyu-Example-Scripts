# frozen_string_literal: true

# Script to replace code values in all columns junk.
# Useful to quickly anonymize data while preserving
# coding vocab and cell onset/offsets.

## Parameters
columns_to_garble = :all
# value to replace each code with.
# can be a function or a specific string
new_val = -> { ('a'..'z').to_a.shuffle.take(4).join }

## Body
require 'Datavyu_API.rb'

columns_to_garble = get_column_list if columns_to_garble == :all
columns_to_garble.each do |colname|
  puts "Garbling #{colname}..."
  col = get_column(colname)
  col.cells.each do |cell|
    col.arglist.each do |code|
      nval = new_val.respond_to?(:call) ? new_val.call : new_val
      cell.change_code(code, nval)
    end
  end
  set_column(col)
end
