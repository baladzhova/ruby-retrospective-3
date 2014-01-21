# http://fmi.ruby.bg/tasks/1/solutions/47

class Integer
  def prime?
    return false if self < 0

    2.upto(self - 1).all? { |divisor| remainder(divisor).nonzero? }
  end

  def prime_factors
    factors = []
    number = self

    2.upto(self.abs) do |factor|
      while (number % factor).zero? and factor.prime?
        factors << factor and number /= factor
      end
    end

    factors
  end

  def harmonic
    harmonic_number = Rational(1, 1)

    2.upto(self.abs) do |number|
      harmonic_number += Rational(1, number)
    end

    harmonic_number
  end

  def digits
    number = self.abs.to_s
    digits_list = []

    number.each_char { |i| digits_list << i.to_i }

    digits_list
  end
end

class Array
  def frequencies
    result = {}

    self.each do |key|
      if result.has_key?(key)
        result[key] += 1
      else
        result[key] = 1
      end
    end

    result
  end

  def average
    average_sum = 0.0

    self.each do |number|
      average_sum += number
    end

    average_sum / self.length
  end

  def drop_every(n)
    result = []

    self.each_with_index do |element, index|
      result << element unless index % n == n - 1
    end

    result
  end

  def combine_with(other)
    self.zip(other).flatten.compact
  end
end