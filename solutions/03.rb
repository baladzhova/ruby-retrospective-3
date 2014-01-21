module Graphics
  module Renderers
    class Ascii
      def self.visualize(canvas)
        (canvas.send :canvas).map(&:join).join "\n"
      end
    end

    class Html
      HTML_BEGINNING = "<!DOCTYPE html>
    <html>
    <head>
      <title>Rendered Canvas</title>
      <style type=\"text/css\">
        .canvas {
          font-size: 1px;
          line-height: 1px;
        }
        .canvas * {
          display: inline-block;
          width: 10px;
          height: 10px;
          border-radius: 5px;
        }
        .canvas i {
          background-color: #eee;
        }
        .canvas b {
          background-color: #333;
        }
      </style>
    </head>
    <body>
      <div class=\"canvas\">\n"
      HTML_ENDING = "    </div>
    </body>
    </html>"

      def self.visualize(canvas)
        html = (canvas.send :canvas).map(&:join).join "<br>\n"
        html.gsub!('@', "<b></b>").gsub!('-', "<i></i>")
        html.insert(0, HTML_BEGINNING).concat('\n' + HTML_ENDING)
      end
    end
  end

  class Canvas
    include Renderers
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @canvas = Array.new(width) { Array.new(height, '-') }
    end

    def set_pixel(width, height)
      @canvas[height][width] = '@'
    end

    def pixel_at?(width, height)
      @canvas[height][width] == '@'
    end

    def draw(figure)
      figure.draw self
    end

    def render_as(renderer)
      renderer.visualize self
    end

    private
    attr_reader :canvas
  end

  class Point
    include Comparable
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def ==(other)
      @x == other.x and @y == other.y
    end

    def eql?(other)
      self == other
    end

    def hash
      (@x.to_s + @y.to_s).hash
    end

    def <(other)
      if @x == other.x
        @y < other.y
      elsif @x < other.x
        true
      else
        false
      end
    end

    def <=>(other)
      if @x == other.x
        @y <=> other.y
      else
        @x <=> other.x
      end
    end

    def draw(canvas)
      canvas.set_pixel x, y
    end
  end

  module BresenhamAlgorithm
    def bresenham(left, right)
      left, right, slope = adjust_points left, right
      characteristics = set_characteristics left, right
      compute_points left, right, slope, characteristics
    end

    private

    def adjust_points(left, right)
      slope = (left.y - right.y).abs > (left.x - right.x).abs

      if slope
        [Point.new(left.y, left.x), Point.new(right.y, right.x), slope]
      else
        [left, right, slope]
      end
    end

    def set_characteristics(left, right, characteristics = {})
      characteristics[:dx] = right.x - left.x
      characteristics[:dy] = (left.y - right.y).abs

      characteristics[:error] = (characteristics[:dx] / 2).to_i

      characteristics[:y_step] = left.y < right.y ? 1 : -1
      characteristics[:y] = left.y

      characteristics
    end

    def compute_points(left, right, slope, characteristics)
      points = []

      left.x.upto right.x do |x|
        y = characteristics[:y]
        slope ? points << Point.new(y, x) : points << Point.new(x, y)

        compute_error characteristics
      end

      points
    end

    def compute_error(characteristics)
      characteristics[:error] -= characteristics[:dy]

      if characteristics[:error] <= 0
        characteristics[:y] += characteristics[:y_step]
        characteristics[:error] += characteristics[:dx]
      end
    end
  end

  class Line
    include BresenhamAlgorithm
    attr_reader :from, :to

    def initialize(from, to)
      @from, @to = from < to ? [from, to] : [to, from]
    end

    def ==(other)
      @from == other.from and @to == other.to
    end

    def eql?(other)
      self == other
    end

    def hash
      (@from.to_s + @to.to_s).hash
    end

    def draw(canvas)
      points = bresenham @from, @to
      points.map { |point| canvas.set_pixel point.x, point.y }
    end
  end

  class Rectangle
    attr_reader :left, :right

    def initialize(left, right)
      @left, @right = left < right ? [left, right] : [right, left]
    end

    def top_left
      if @left.y > @right.y
        Point.new @left.x, @right.y
      else
        @left
      end
    end

    def top_right
      if @left.y < @right.y
        Point.new @right.x, @left.y
      else
        @right
      end
    end

    def bottom_left
      if @left.y < @right.y
        Point.new @left.x, @right.y
      else
        @left
      end
    end

    def bottom_right
      if @left.y > @right.y
        Point.new @right.x, @left.y
      else
        @right
      end
    end

    def ==(other)
      get_points.sort == (other.send :get_points).sort
    end

    def eql?(other)
      self == other
    end

    def hash
      (@left.to_s + @right.to_s).hash
    end

    def draw(canvas)
      sides = get_sides
      sides.map { |line| canvas.draw line }
    end

    private

    def get_points
      [] << top_right << top_left << bottom_right << bottom_left
    end

    def get_sides
      sides = []

      sides << Line.new(top_left, top_right)
      sides << Line.new(bottom_left, bottom_right)
      sides << Line.new(top_left, bottom_left)
      sides << Line.new(top_right, bottom_right)

      sides
    end
  end
end

module Graphics
  canvas = Canvas.new 30, 30

  # Door frame and window
  canvas.draw Rectangle.new(Point.new(3, 3), Point.new(18, 12))
  canvas.draw Rectangle.new(Point.new(1, 1), Point.new(20, 28))

  # Door knob
  canvas.draw Line.new(Point.new(4, 15), Point.new(7, 15))
  canvas.draw Point.new(4, 16)

  # Big "R"
  canvas.draw Line.new(Point.new(8, 5), Point.new(8, 10))
  canvas.draw Line.new(Point.new(9, 5), Point.new(12, 5))
  canvas.draw Line.new(Point.new(9, 7), Point.new(12, 7))
  canvas.draw Point.new(13, 6)
  canvas.draw Line.new(Point.new(12, 8), Point.new(13, 10))

  puts canvas.render_as(Renderers::Ascii)
  puts canvas.render_as(Renderers::Html)

=begin
  ascii_text = canvas.render_as(Renderers::Ascii)
  html_text = canvas.render_as(Renderers::Html)

  File.open("E:/FMI/Ruby/Ruby 2.1/ascii.txt", 'w') do |f|
    f.write ascii_text
  end

  File.open("E:/FMI/Ruby/Ruby 2.1/door.html", 'w') do |f|
    f.write html_text
  end=end

end

canvas = Graphics::Canvas.new 5, 5

canvas.set_pixel 0, 0
canvas.set_pixel 1, 1
canvas.set_pixel 2, 2

puts canvas.render_as(Graphics::Renderers::Ascii)
puts canvas.render_as(Graphics::Renderers::Html)