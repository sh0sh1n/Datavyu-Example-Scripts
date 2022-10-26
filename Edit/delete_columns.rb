# frozen_string_literal: true

require 'Datavyu_API.rb'

## Params
# List of columns to delete. Special value :all will delete all columns
# minus the columns_to_keep
columns_to_delete = :all

# List of columns to keep
columns_to_keep = %w[keep1 keep2]

## Body

cols_to_rm = columns_to_delete == :all ? get_column_list : columns_to_delete
cols_to_rm -= columns_to_keep
cols_to_rm.each { |x| delete_column(x) }
