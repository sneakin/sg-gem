module PackedStructSpec
  class Beta < SG::PackedStruct.new([:type, :uint16],
                                       [:value, :int64])
  end

  class Alpha
    include SG::AttrStruct
    include SG::PackedStruct
    define_packing([:a, :uint8],
                   [:b, :int16l],
                   [:c, :int16b],
                   [:d, :int32 ],
                   [:e, :uint64],
                   [:f, :uint8, lambda { a*4 } ],
                   [:g, :string, :e ],
                   [:h, Beta ],
                   [:i, Beta, :b ])
    init_attr :c, 123
    init_attr :d, lambda { (c * 3.707).round }
  end
end
