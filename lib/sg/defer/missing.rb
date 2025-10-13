module SG::Defer
  module Missing
    def method_missing(*a, **o, &b)
      self.class.new {
        self.wait.send(*SG::Defer.wait_for(a), **SG::Defer.wait_for(o), &b)
      }
    end
  end
end
