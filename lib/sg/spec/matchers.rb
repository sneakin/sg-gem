require 'sg/ext'
using SG::Ext

module SG::Spec
  module Matchers
    def expect_clock_at t, dt = 0.0001
      start = Time.now
      yield
      expect(Time.now - start).to be_within(dt).of(t)
    end
  end
end
