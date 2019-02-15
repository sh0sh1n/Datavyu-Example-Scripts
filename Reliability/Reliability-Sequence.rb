## Parameters
pri_column_name = 'pri'
rel_column_name = 'rel'
disagree_column_name = 'disagree'
codes_to_check = %w(code)
window_size = 500
output_file = '~/Desktop/reliability_code.csv'
delimiter = ','

## Body
require 'Datavyu_API.rb'
require 'matrix'

class Matrix
  public :"[]=", :set_element, :set_component
end

class SequenceMatcher
  attr_accessor :s1, :s2, :table, :score_funct, :cseq, :unpaired_s1, :unpaired_s2, :solved

  def initialize(list1, list2, &scoring_function)
    self.s1 = list1
    self.s2 = list2
    self.score_funct = scoring_function

    self.table = Matrix.build(list1.size+1, list2.size+1) do |row, col|
      val = nil
      if row == 0
        val = -col
      elsif col == 0
        val = -row
      end
      val
    end
    self.table[0,0] = 0

    self.cseq = []
    self.unpaired_s1 = []
    self.unpaired_s2 = []
    self.solved = false
  end

  # Run Needleman-Wunsch
  def solve
    (1..s1.size).each do |i|
      (1..s2.size).each do |j|
        pri_cell = s1[i-1]
        rel_cell = s2[j-1]
        pval1 = table[i-1, j] + score_funct.call(pri_cell, nil)
        pval2 = table[i, j-1] + score_funct.call(rel_cell, nil)
        pval3 = table[i-1, j-1] + score_funct.call(pri_cell, rel_cell)
        max_val = [pval1, pval2, pval3].max
        self.table[i, j] = max_val
      end
    end

    self.solved = true
    self.compute_match
  end

  # Find the common sequence, and unpaired
  def compute_match
    self.solve unless self.solved

    i, j = s1.size, s2.size
    while(i > 0 || j > 0)
      pval1 = (i==0)? nil : table[i-1, j]
      pval2 = (j==0)? nil : table[i, j-1]
      pval3 = table[i-1, j-1]
      max_val = [pval1, pval2, pval3].compact.max
      # puts "max: #{max_val}, #{i}, #{j}"
      if pval3 == max_val
        # puts "match"
        i -= 1
        j -= 1
        cseq << [self.s1[i], self.s2[j]]
      elsif pval2 == max_val
        # puts "unpaired rel"
        j -= 1
        self.unpaired_s2 << s2[j]
      elsif pval1 == max_val
        # puts "unpaired pri"
        i -= 1
        self.unpaired_s1 << s1[i]
      else
        raise "Reconstruction error. i=#{i}, j=#{j}"
      end
    end
    self.cseq.reverse!
    self.unpaired_s1.reverse!
    self.unpaired_s2.reverse!
  end

  def print_table(outfile=nil)
    out = self.table.row_vectors.map{ |r| r.to_a.map{ |e| sprintf('%5d', e) }.join(', ') }
    # 0.upto(s1.size-1){ |r| out << self.table.row(r).to_a.map{ |x| sprintf('%5d', x) }.join(', ') }
    if outfile.nil?
      puts out
    else
      outfile = File.open(File.expand_path(outfile), 'w+')
      outfile.puts out
    end
  end

  def pairs
    return self.cseq
  end
end

pri_col = get_column(pri_column_name)
rel_col = get_column(rel_column_name)
score_function = lambda do |pri, rel|
  return -1 if (pri.nil? || rel.nil?)
  return -100 if (pri.onset - rel.onset).abs > window_size

  score = 0
  codes_to_check.each do |c|
    if pri.get_code(c) == rel.get_code(c)
      score += 5
    end
  end
  return score
end

sol = SequenceMatcher.new(pri_col.cells, rel_col.cells, &score_function)
sol.solve
# sol.print_table('~/Desktop/table.csv')
# puts sol.cseq.map{ |p| p.map(&:ordinal).join(', ') }.join("\n")
# p sol.unpaired_s1.map(&:ordinal).join(', ')
# p sol.unpaired_s2.map(&:ordinal).join(', ')


disagree_col = new_column(disagree_column_name, 'comment')
# Insert disagree cells for unpaired cells.
(sol.unpaired_s1 + sol.unpaired_s2).each do |cell|
  ncell = disagree_col.new_cell(cell)
end
# Insert disagree cells for code mismatches
sol.cseq.each do |pri, rel|
  if codes_to_check.any? { |c| pri.get_code(c) != rel.get_code(c) }
    ncell = disagree_col.new_cell()
    ncell.onset = [pri.onset, rel.onset].min
    ncell.offset = [pri.offset, rel.offset].max
  end
end
set_column(disagree_col)

# Calculate agreement percent.
denom = [pri_col.cells.size, rel_col.cells.size].max
agree_perc = 100.0 * sol.pairs.size.to_f / denom.to_f
puts "Agreement for onset:\t%.2f" % (agree_perc)

# For each code, compute number of pairings which agree on that code
codes_to_check.each do |code|
  agree_pairings = sol.pairs.select{ |x| x[0].get_code(code) == x[1].get_code(code) }
  agree_perc = 100.0 * agree_pairings.size.to_f / denom.to_f
  puts "Agreement for code #{code}:\t%.2f" % (agree_perc)
end

# Output the data to output file.
data = []
header = [pri_column_name, rel_column_name].map do |colname|
  (%w(ordinal onset) + codes_to_check).map{ |x| "#{colname}_#{x}" }
end.flatten
data << header.join(delimiter)

sol.pairs.each do |pair|
  row = pair.map do |cell|
    (%w(ordinal onset) + codes_to_check).map{ |x| cell.get_code(x) }
  end.flatten
  data << row.join(delimiter)
end

# Unpaired pri cells
unpaired_pri = pri_col.cells.reject{ |x| sol.pairs.map{ |y| y[0]}.include?(x) }
unpaired_pri.each do |cell|
  row = (%w(ordinal onset) + codes_to_check).map{ |x| cell.get_code(x) } + [''] * (codes_to_check.size + 2)
  data << row.join(delimiter)
end

# Unpaired rel cells
unpaired_rel = rel_col.cells.reject{ |x| sol.pairs.map{ |y| y[1]}.include?(x) }
unpaired_rel.each do |cell|
  row = [''] * (codes_to_check.size + 2) + (%w(ordinal onset) + codes_to_check).map{ |x| cell.get_code(x) }
  data << row.join(delimiter)
end

outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data
outfile.close
