using SG::Ext

module SG::Units
  module SI
    # Standard and binary metric prefixes
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
      kibi: (1 << 10).to_f,
      mebi: (1 << 20).to_f,
      gibi: (1 << 30).to_f,
      tibi: (1 << 40).to_f,
      pebi: (1 << 50).to_f,
      exbi: (1 << 60).to_f,
      zebi: (1 << 70).to_f,
      yobi: (1 << 80).to_f
    }

    # Generate modules for each prefix that derive from
    # {SG::Units} or any unit subclass using {#[]}.
    Prefixes.each do |prefix, scale|
      prefix = prefix.to_s
      next if prefix.blank?
      mod = nil
      mod = Module.new do
        define_singleton_method(:[]) do |base|
          SG::Units.scaled_unit("#{prefix}#{base.name.downcase}", base, scale)
        end        
        define_singleton_method(:const_missing) do |unit|
          const_set(unit, mod[SG::Units.const_get(unit.to_s)])
        end
      end
      const_set(prefix.camelize, mod)
    end    
  end
end
