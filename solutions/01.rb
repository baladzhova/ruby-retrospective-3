class Integer
  def prime?
    return false if self < 2
    (2..pred).all? { |divisor| remainder(divisor).nonzero? }
  end

  def prime_factors
    return [] if self == 1
    factor = (2..abs).find { |x| remainder(x).zero? }
    [factor] + (abs / factor).prime_factors
  end

  def harmonic
    (1..self).map { |number| Rational(1, number) }.reduce(:+)
  end

  def digits
    abs.to_s.chars.map(&:to_i)
  end
end

class Array
  def frequencies
    each_with_object Hash.new(0) do |value, frequency|
      frequency[value] += 1
    end
  end

  def average
    reduce(:+) / length.to_f
  end

  def drop_every(n)
    select.each_with_index { |_, index| index % n != n - 1 }
  end

  def combine_with(other)
    empty? ? other : zip(other).flatten.compact
  end
end