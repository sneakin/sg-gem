module SG
  # A class that noops arithmetic like it wasn't there.
  # An instance is useful for kicking off #reduce on the first element.
  class Ignored
    %w{ + - * / & & | ^ }.each do |op|
      define_method(op) do |other|
        other
      end
    end

    %w{ eql? equal? == === }.each do |op|
      define_method(op) do |other|
        true
      end
    end
  end    
end
