class Tile
  include ActiveModel::Serialization

  attr_accessor :x, :y, :type

  def initialize(x:, y:, type:)
    @x = x
    @y = y
    @type = type
  end

  def inspect
    "<#{x},#{y} - #{to_s}>"
  end

  def as_json(options = nil)
    to_s
  end

  def to_s
    if wall?
      '#'
    else
      '.'
    end
  end

  def to_h
    position
  end

  def position
    {"x" => @x, "y" => @y}
  end

  def to_position
    Position.new(position)
  end

  def wall?
    @type == :wall
  end

  def ==(other)
    @x == other.x && @y == other.y
  end

  def hash
    [@x, @y].hash
  end
end