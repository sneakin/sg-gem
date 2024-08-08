require 'sg/ext/proc'
using SG::Ext

module SG
  class SkipUnless
    def initialize test, src, &cb
      @test = test
      @src = src
      @block = cb
    end

    def eql? other
      @src.eql?(other)
    end
    
    def _src; @src; end
    
    def _test_passes?
      @test && (@block == nil || @block.call(@src))
    end
    
    def method_missing mid, *a, **o, &b
      if _test_passes?
        @src.send(mid, *a, **o, &b)
      else
        self.class === @src ? @src._src : @src
      end
    end

    def skip_unless test = true, &b
      s = SG::SkipUnless.new(test, self, &b)
      s._test_passes?? @src : s
    end

    def skip_when test = false, &b
      s = SG::SkipUnless.new(!test, self, &b&.not)
      s._test_passes?? @src : s
    end
  end
end
