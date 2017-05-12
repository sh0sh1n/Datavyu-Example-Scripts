# Insert columns.

## Parameters
# Behavior for columns that already exist. Handled values are:
# :skip     - do nothing
# :replace  - replace existing column
# :update   - add new codes, remove unlisted codes
existing_column_behavior = :update
map = {
  'id' => %w(study subj visit sex tdate bdate bweight bheight leg walkdate cruisedate hkdate bellydate),
  'task' => %w(task),
  'moving' => %w(steps direction)
}

## Body
require 'Datavyu_API.rb'
map.each_pair do |column_name, codes|
  column = new_column(column_name, *codes)

  if get_column_list().include?(column_name)
    old_column = get_column(column_name)

    case existing_column_behavior
    when :skip
      puts "Skipping column #{column} since it already exists"
      next
    when :replace
      column = old_column
    when :update
      codes_to_remove = old_column.arglist - codes
      codes_to_add = codes - old_column.arglist

      codes_to_remove.each{ |c| old_column.remove_code(c) }
      codes_to_add.each{ |c| old_column.add_code(c) }
      column = old_column
    end
  end

  set_column(column)
end
