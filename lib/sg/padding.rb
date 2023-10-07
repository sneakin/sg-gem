module SG
  def self.pad_size amount, to = nil
    to ||= 4
    p = amount & (to-1)
    p = to - p if p > 0
    p
  end

  def self.pad n, to = nil
    n + pad_size(n, to)
  end
end
