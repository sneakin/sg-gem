module SG
  class SkipUnless
    def initialize test, src, &cb
      @test = test
      @src = src
      @block = cb
    end

    def method_missing mid, *a, **o, &b
      if @test && (@block == nil || @block.call(@src))
        @src.send(mid, *a, **o, &b)
      else
        @src
      end
    end
  end
end
