using SG::Ext

module SG::Units
  module SI
    Prefixes = {
      '' => 1,
      deci: 1e-1,
      deca: 1e1,
      centi: 1e-2,
      hecto: 1e2,
      milli: 1e-3,
      kilo: 1e3,
      micro: 1e-6,
      mega: 1e6,
      nano: 1e-9,
      giga: 1e9,
      pico: 1e-12,
      tera: 1e12,
      femto: 1e-15,
      peta: 1e15,
      atto: 1e-18,
      exa: 1e18,
      zepto: 1e-21,
      zetta: 1e21,
      yocto: 1e-24,
      yotta: 1e24,
      ronto: 1e-27,
      ronna: 1e27,
      quecto: 1e-30,
      quetta: 1e30,
      kiba: (1 << 10).to_f,
      meba: (1 << 20).to_f,
      giba: (1 << 30).to_f,
      tiba: (1 << 40).to_f,
      peba: (1 << 50).to_f
    }
    
    def self.si_prefix unit_s
      unit_s = unit_s.to_s
      unit_n = unit_s.camelize
      unit = const_get("SG::Units::#{unit_n}")
      Prefixes.each do |prefix, scale|
        const_set("#{prefix.to_s.camelize}#{unit_n}",
                  SG::Units.scaled_unit("#{prefix}#{unit_s.downcase}", unit, scale))
      end
    end

    %w{ Meter Second Hertz Gram
        Liter Mole Newton Watt Joule
        Volt Ampere Ohm Byte Bit
    }.each(&method(:si_prefix))
  end
end
