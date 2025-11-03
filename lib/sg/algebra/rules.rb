module SG::Algebra
  Rules =
    [
     #
     # General rules
     #
     
     # self -> self()
     lambda { Arithmetic === _1 ?  _1.call : _1 },
     # a OP b -> a' OP b'
     lambda { (BinOp === _1 &&
          _1.dup.tap { |n|
            n.left = simplify(n.left)
            n.right = simplify(n.right)
          }) || _1
     },

     #
     # Addition
     #
     
     # 0 + a -> a
     lambda { (Addition === _1 && _1.left == 0 && _1.right) || _1 },
     # a + 0 -> a
     lambda { (Addition === _1 && _1.right == 0 && _1.left) || _1 },
     # X + (a + Y) -> (X+Y) + a
     lambda { (Addition === _1 && Numeric === _1.left && Addition === _1.right && Numeric === _1.right.right &&
          (_1.left + _1.right.right) + _1.right.left) || _1 },
     # X + (Y + a) -> (X+Y) + a
     lambda { (Addition === _1 && Numeric === _1.left && Addition === _1.right && Numeric === _1.right.left &&
          (_1.left + _1.right.left) + _1.right.right) || _1 },
     # (X + a) + Y -> (X+Y) + a
     lambda { (Addition === _1 && Numeric === _1.right && Addition === _1.left && Numeric === _1.left.left &&
          (_1.left.left + _1.right) + _1.left.right) || _1 },
     # (a + X) + Y -> a + (X+Y)
     lambda { (Addition === _1 && Numeric === _1.right && Addition === _1.left && Numeric === _1.left.right &&
          (_1.left.left + (_1.left.right + _1.right))) || _1 },

     #
     # Subtraction
     #
     
     # 0 - a -> -a
     lambda { (Subtraction === _1 && _1.left == 0 && -_1.right) || _1 },
     # a - 0 -> a
     lambda { (Subtraction === _1 && _1.right == 0 && _1.left) || _1 },
     # a - a -> 0
     lambda { (Subtraction === _1 && _1.left == _1.right &&
          0) || _1 },

     #
     # Products
     #
     
     # a * a -> a ** 2
     lambda { (Product === _1 && _1.left == _1.right && _1.left ** 2) || _1 },
     # a ** b * a -> a ** (b+1)
     lambda { (Product === _1 && Exponent === _1.left && _1.left.left == _1.right &&
          _1.left.dup.tap { |n| n.right += 1 }) || _1 },
     # a * a ** b -> a ** (b+1)
     lambda { (Product === _1 && Exponent === _1.right && _1.right.left == _1.left &&
          _1.right.dup.tap { |n| n.right += 1 }) || _1 },
     # (a ** b) * (a ** c) -> a ** (b+c)
     lambda { (Product === _1 && Exponent === _1.left && Exponent === _1.right &&
          _1.left.left == _1.right.left &&
          _1.left.left ** (_1.left.right + _1.right.right)) || _1 },
     # (a / b) * a -> 1 / b
     lambda { |n| (Product === n && (Division === n.left && n.left.left == n.right) && Division.new(1, n.left.right)) || n },
     # (a / b) * b -> a
     lambda { |n| (Product === n && (Division === n.left && n.left.right == n.right) && n.left.left) || n },
     # 0 * a -> 0
     lambda { (Product === _1 && _1.left == 0 && 0) || _1 },
     # a * 0 -> 0
     lambda { (Product === _1 && _1.right == 0 && 0) || _1 },
     # 1 * a -> a
     lambda { (Product === _1 && _1.left == 1 && _1.right) || _1 },
     # a * 1 -> a
     lambda { (Product === _1 && _1.right == 1 && _1.left) || _1 },
     # X * (a * Y) -> (X*Y) * a
     lambda { (Product === _1 && Numeric === _1.left && Product === _1.right && Numeric === _1.right.right &&
          (_1.left * _1.right.right) * _1.right.left) || _1 },
     # X * (Y * a) -> (X*Y) * a
     lambda { (Product === _1 && Numeric === _1.left && Product === _1.right && Numeric === _1.right.left &&
          (_1.left * _1.right.left) * _1.right.right) || _1 },
     # (X * a) * Y -> (X*Y) * a
     lambda { (Product === _1 && Numeric === _1.right && Product === _1.left && Numeric === _1.left.left &&
          (_1.left.left * _1.right) * _1.left.right) || _1 },
     # (a * X) * Y -> a * (X*Y)
     lambda { (Product === _1 && Numeric === _1.right && Product === _1.left && Numeric === _1.left.right &&
          (_1.left.left * (_1.left.right * _1.right))) || _1 },

     #
     # Division
     #
     
     # a / 1 -> a
     lambda { (Division === _1 && _1.right == 1 && _1.left) || _1 },
     # 0 / a -> 0
     lambda { (Division === _1 && _1.left == 0 && _1.left) || _1 },
     # a / a => 1
     lambda { (Division === _1 && _1.left == _1.right && 1) || _1 },
     # (X + b) / X -> 1 + (b/X)
     lambda { (Division === _1 && Addition === _1.left && _1.left.left == _1.right &&
          (1 + (_1.left.right / _1.right))) || _1 },
     # (a + X) / X -> (a/X) + 1
     lambda { (Division === _1 && Addition === _1.left && _1.left.right == _1.right &&
          ((_1.left.left / _1.right) + 1)) || _1 },
     # (a + b) / X -> (a/X) + (b/X)
     lambda { (Division === _1 && Addition === _1.left && Numeric === _1.right &&
          ((_1.left.left / _1.right) + (_1.left.right / _1.right))) || _1 },
     # (X - b) / X -> 1 - (b/X)
     lambda { (Division === _1 && Subtraction === _1.left && _1.left.left == _1.right &&
          (1 - (_1.left.right / _1.right))) || _1 },
     # (a - X) / X -> (a/X) - 1
     lambda { (Division === _1 && Subtraction === _1.left && _1.left.right == _1.right &&
          ((_1.left.left / _1.right) - 1)) || _1 },
     # (a - b) / X -> (a/X) - (b/X)
     lambda { (Division === _1 && Subtraction === _1.left && Numeric === _1.right &&
          ((_1.left.left / _1.right) - (_1.left.right / _1.right))) || _1 },
     # (X * b) / Y -> (X/Y) * b
     lambda { (Division === _1 && Product === _1.left && Numeric === _1.left.left && Numeric === _1.right &&
          (_1.left.right * (_1.left.left / _1.right))) || _1 },
     # (a * X) / Y -> (X/Y) * a
     lambda { (Division === _1 && Product === _1.left && Numeric === _1.left.right && Numeric === _1.right &&
          (_1.left.left * (_1.left.right / _1.right))) || _1 },
     # (a / b) / (c / d) -> (ad / bc)
     lambda { (Division === _1 && Division === _1.left && Division === _1.right &&
          (_1.left.left * _1.right.right) /
          (_1.left.right * _1.right.left)) || _1 },
     # a / (c / d) -> ad / c
     lambda { (Division === _1 && !(Division === _1.left) && Division === _1.right &&
          (_1.left * _1.right.right) / _1.right.left) || _1 },
     # (a / b) / c -> a / bc
     lambda { (Division === _1 && (Division === _1.left) && !(Division === _1.right) &&
          (_1.left.left / (_1.left.right * _1.right))) || _1 },
     # (a * b) / a -> b
     lambda { |n| (Division === n && (Product === n.left && n.left.left == n.right) && n.left.right) || n },
     # (a * b) / b -> a
     lambda { |n| (Division === n && (Product === n.left && n.left.right == n.right) && n.left.left) || n },

     #
     # Powers
     #
     
     # a ** 1 -> a
     lambda { (Exponent === _1 && _1.right == 1 && _1.left) || _1 },
     # a ** 0 -> 1
     lambda { (Exponent === _1 && _1.right == 0 && 1) || _1 },
     # (a ** b) ** c -> a ** (b*c)
     lambda { (Exponent === _1 && Exponent === _1.left &&
          _1.left.left ** (_1.left.right * _1.right)) || _1 },
     # (a * X) ** b -> (a**b) * (X**b)
     # (X * a) ** b -> (X**b) * (a**b)
     lambda { (Exponent === _1 && Product === _1.left && Numeric === _1.right &&
          (Numeric === _1.left.left || Numeric === _1.left.right) &&
          ((_1.left.left ** _1.right) * (_1.left.right ** _1.right))) || _1 },

     #
     # todo Functions
     #
    ]
end
