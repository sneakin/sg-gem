# -*- coding: utf-8 -*-
module SG::Units
  Length = Dimension.new(:length)

  class Meter < Unit
    self.dimension = Length

    def self.name
      super || "meter"
    end

    def self.abbrev
      super || name[0]
    end
  end

  Inch = scaled_unit('inch', Meter, 0.0254, abbrev: 'in')
  Foot = scaled_unit('foot', Inch, 12.0)
  Yard = scaled_unit('yard', Foot, 3.0)
  Mile = scaled_unit('mile', Foot, 5280.0)
  Cubit = scaled_unit('cubit', Meter, 0.5292)
  Palm = scaled_unit('palm', Cubit, 1 / 7.0)
  Finger = scaled_unit('finger', Palm, 1 / 4.0)

  Area = Length * Length
  Meter2 = Meter * Meter
  Meter2.name = 'meter²'
  Meter2.abbrev = 'm²'
  Meter2.dimension = Area
  Volume = Length * Area
  Meter3 = Meter * Meter * Meter
  Meter3.name = 'meter³'
  Meter3.abbrev = 'm³'
  Meter3.dimension = Volume
  Liter = scaled_unit('liter', Meter3, 1e-3)
  
  Time = Dimension.new(:time)

  class Second < Unit
    self.dimension = Time
    self.name = 'second'
    self.abbrev = 's'
  end

  Minute = scaled_unit('minute', Second, 60.0)
  Hour = scaled_unit('hour', Minute, 60.0)
  Day = scaled_unit('day', Hour, 24.0)
  Week = scaled_unit('week', Day, 7.0)
  Year = scaled_unit('year', Day, 365.242)

  # todo frequency as 1 / time [in a medium?]
  Frequency = 1 / Time

  Hertz = (1 / Second).tap do |h|
    #self.dimension = Frequency
    h.name = 'hertz'
    h.abbrev = 'Hz'
  end

  Temperature = Dimension.new(:temperature)
  
  class Kelvin < Unit
    self.dimension = Temperature
    self.name = 'Kelvin'
    self.abbrev = 'K'
  end

  Celsius = scaled_unit('Celsius', Kelvin, 1, 273.15)
  Fahrenheit = scaled_unit('Fahrenheit', Celsius, 5/9.0, -32)

  Rotation = Dimension.new(:rotation)
  
  class Radian < Unit
    self.dimension = Rotation
    self.name = "radian"
    self.abbrev = 'r'
  end

  RotUnit = scaled_unit('rotunit', Radian, Math::PI * 2)
  Degree = scaled_unit('degree', Radian, Math::PI / 180.0, abbrev: '°')

  # todo seconds -> degrees -> miles [on a planet?]
  
  Mass = Dimension.new(:mass)
  
  class Gram < Unit
    self.dimension = Mass
    self.name = 'gram'
    self.abbrev = 'g'
  end

  KiloGram = scaled_unit('kilogram', Gram, 1000, abbrev: 'kg')
  Ounce = scaled_unit('ounce', Gram, 28.3495, abbrev: 'oz')
  PoundM = scaled_unit('pound', Ounce, 8, abbrev: 'lbs')
  
  Velocity = Length / Time
  Acceleration = Velocity / Time
  Force = Mass * Acceleration

  Meter_Per_Sec = Meter / Second
  Meter_Per_Sec2 = Meter_Per_Sec / Second

  class Newton < KiloGram * Meter / Second / Second
    #self.dimension = Force
    self.name = 'newton'
    self.abbrev = 'N'
  end
  # Or:
  # Newton = (KiloGram * Meter / Second / Second).tap do |n|
  #   n.name = 'newton'
  #   n.abbrev = 'N'
  # end

  Pound = scaled_unit('pound', Newton, 4.44822, abbrev: 'lbs')

  Count = Dimension.new(:count)
  
  class Counted < Unit
    self.dimension = Count
  end

  Mole = scaled_unit('mole', Counted, 6.02214076e23)
  
  Energy = Force * Length

  class Joule < Newton * Meter
    self.name = 'Joule'
    self.abbrev = 'J'
  end
  
  Power = Energy * Time

  class Watt < Joule * Second
    self.name = 'Watt'
    self.abbrev = 'W'
  end

  Charge = Dimension.new(:charge)

  class ElectronCount < Unit
    self.dimension = Charge
  end
  Columb = scaled_unit('Columb', ElectronCount, 6.241509074e18)

  EPotential = Energy / Charge
  Current = Charge / Time
  PowerV = EPotential * Current

  Volt = Joule / Columb
  Ampere = Columb / Second
  Ohm = Volt / Ampere
  PowerVsi = Volt * Ampere
end
