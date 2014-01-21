module Graphics
  module Figure
    def eql?(other)
      variables == other.variables
    end

    alias == eql?

    def hash
      variables.hash
    end

    def variables
      instance_variables.map { |variable| instance_variable_get(variable) }
    end
  end

  class Point
    include Figure
    include Comparable
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
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

  class Line
    include Figure
    attr_reader :from, :to

    def initialize(from, to)
      @from, @to = [from, to].sort
    end

    def draw(canvas)
      points = BresenhamAlgorithm.new(@from, @to).rasterize_on
      points.map { |point| canvas.set_pixel point.x, point.y }
    end

    class BresenhamAlgorithm
      def initialize(from, to)
        @from = from
        @to = to
      end

      def slope?
        (@from.y - @to.y).abs > (@from.x - @to.x).abs
      end

      def rasterize_on
        @drawing_from, @drawing_to = adjust_points
        set_characteristics
        compute_points
      end

      def adjust_points
        if slope?
          [
            Point.new(@from.y, @from.x),
            Point.new(@to.y, @to.x)
          ]
        else
          [ @from, @to ]
        end
      end

      def error_delta
        @delta_x = @drawing_to.x - @drawing_from.x
        @delta_y = (@drawing_from.y - @drawing_to.y).abs

        @error = (@delta_x / 2).to_i
      end

      def set_characteristics
        error_delta
        @y_step = @drawing_from.y < @drawing_to.y ? 1 : -1
        @y = @drawing_from.y
      end

      def compute_points
        points = []

        @drawing_from.x.upto(@drawing_to.x) do |x|
          slope? ? points << Point.new(@y, x) : points << Point.new(x, @y)
          compute_error
        end

        points
      end

      def compute_error
        @error -= @delta_y

        if @error <= 0
          @y += @y_step
          @error += @delta_x
        end
      end
    end
  end

  class Rectangle
    include Figure

    attr_reader :left, :right
    attr_reader :top_left, :top_right, :bottom_left, :bottom_right

    def initialize(left, right)
      @left, @right = [left, right].sort

      @top_left = Point.new left.x, [left.y, right.y].min
      @bottom_left = Point.new left.x, [left.y, right.y].max
      @top_right = Point.new right.x, [left.y, right.y].min
      @bottom_right = Point.new right.x, [left.y, right.y].max
    end

    def draw(canvas)
      sides.each { |side| side.draw(canvas) }
    end

    private

    def sides
      [
        Line.new(@top_left, @top_right),
        Line.new(@bottom_left, @bottom_right),
        Line.new(@top_left, @bottom_left),
        Line.new(@top_right, @bottom_right),
      ]
    end
  end

  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @canvas = {}
    end

    def set_pixel(width, height)
      @canvas[[width, height]] = true
    end

    def pixel_at?(width, height)
      @canvas[[width, height]]
    end

    def draw(figure)
      figure.draw(self)
    end

    def render_as(renderer)
      renderer.new(self).visualize
    end
  end

  module Renderers
    class BasicRenderer
      attr_reader :canvas

      def initialize(canvas)
        @canvas = canvas
      end

      def visualize
        raise NotImplementedError
      end
    end

    class Ascii < BasicRenderer
      def visualize
        pixels = 0.upto(canvas.height.pred).map do |y|
          0.upto(canvas.width.pred).map { |x| pixel_at(x, y) }
        end

        join_lines pixels.map { |line| join_pixels_in line }
      end

      private

      def full_pixel
        '@'
      end

      def blank_pixel
        '-'
      end

      def pixel_at(x, y)
        canvas.pixel_at?(x, y) ? full_pixel : blank_pixel
      end

      def join_pixels_in(line)
        line.join('')
      end

      def join_lines(lines)
        lines.join("\n")
      end
    end

    class Html < Ascii
      TEMPLATE = '<!DOCTYPE html>
        <html>
        <head>
          <title>Rendered Canvas</title>
          <style type="text/css">
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
          <div class="canvas">
            %s
          </div>
        </body>
        </html>
      '.freeze

      def visualize
        TEMPLATE % super
      end

      private

      def full_pixel
        '<b></b>'
      end

      def blank_pixel
        '<i></i>'
      end

      def join_lines(lines)
        lines.join('<br>')
      end
    end
  end
end