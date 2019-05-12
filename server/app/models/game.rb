class Game
  include ActiveModel::Serialization
  attr_accessor :world, :iteration, :all_snakes, :alive_snakes, :events

  def setup(width: 100, height: 100)
    @iteration = 0
    @all_snakes = []
    @alive_snakes = []
    @events = []
    @width = width
    @height = height
    @world = Array.new(height) {|y| Array.new(width) {|x|
      type = if x == 0 || y == 0 || x == width - 1 || y == height - 1
        :wall
      end

      if rand(50) == 1
        type = :wall
      end
      Tile.new(x: x, y: y, type: type)
    } }

    $redis.set "map", Marshal.dump(world)

    @safe_tiles = @world.flatten.reject(&:wall?).map(&:to_position)
  end

  def spawn_new_snakes
    new_snakes = Snake.new_snakes

    @possible_spawn_points = @safe_tiles - @alive_snakes.map(&:occupied_space).flatten

    new_snakes.each do |snake|
      spawn_point = @possible_spawn_points.sample
      snake.set_position(spawn_point)
      @alive_snakes.push(snake)
      @possible_spawn_points = @possible_spawn_points.without(spawn_point)
    end
  end

  def tick
    @alive_snakes = Snake.alive.all
    @items = Item.all.to_a
    @events = []

    process_intents
    process_item_pickups

    kill_colliding_snakes

    spawn_new_snakes
    spawn_new_items

    @iteration += 1
  end

  def process_item_pickups
    @items.each do |item|
      collecting_snake = @alive_snakes.detect{|snake| snake.head == item.tile }

      if collecting_snake
        @events.push(Event.new('food_pickup'))
        collecting_snake.items.push item.to_pickup
        collecting_snake.save
        item.destroy
      end
    end
  end

  def spawn_new_items
    # Always have one item of food to pickup
    if !@items.any?(&:food?)
      @items.push Item.create!(item_type: 'food', position: @possible_spawn_points.sample.to_h)
    end
  end

  def to_s
    chars = @world.map{|row| row.map{|tile| tile.to_s }}
    @alive_snakes.each do |snake|
      chars[snake.head.y][snake.head.x] = snake.intent || "@"
      snake.segments.each do |segment|
        chars[segment.y][segment.x] = "~"
      end
    end

    chars.map{|row| row.join }.join("\n")
  end

  def as_json(options = nil)
    {
      alive_snakes: @alive_snakes.map(&:to_game_hash),
      items: @items.map{|item|
        {itemType: item.item_type, position: item.position}
      },
      events: @events.map{|event|
        { type: event.type }
      },
      leaderboard: Snake.leaderboard.map{|snake|
        {id: snake.id, name: snake.name, length: snake.length, isAlive: snake.alive?}
      }
    }
  end

  private

  # Snakes grow every 5 ticks or if they have food
  def should_snake_grow?(snake)
    snake.has_food? || @iteration % 5 == 0
  end

  def process_intents
    @alive_snakes.each do |snake|
      current_position = snake.head
      new_y, new_x = case snake.intent || snake.last_intent
      when 'N' then [current_position.y - 1, current_position.x]
      when 'S' then [current_position.y + 1, current_position.x]
      when 'E' then [current_position.y, current_position.x + 1]
      when 'W' then [current_position.y, current_position.x - 1]
      else [0, 0] # Dead on invalid move
      end

      snake.move(@world[new_y][new_x], should_snake_grow?(snake))
    end
  end

  def kill_colliding_snakes
    # We need this to calculate collisions efficiently
    unsafe_tiles_this_tick = @alive_snakes.map(&:occupied_space).flatten

    dying_snakes = @alive_snakes.select do |snake|
      tile_for(snake.head).wall? ||
      # We expect the head to be in the list - if it's there a second time though,
      # that's a collision with either self of another snake
      unsafe_tiles_this_tick.count(snake.head) > 1
    end

    @events.push(Event.new('kill')) if dying_snakes.any?

    dying_snakes.each(&:kill)
    dying_snakes.each do |dying_snake|
      if dying_snake.length > 10
        Item.create!(item_type: 'dead_snake', position: dying_snake.occupied_space.last.to_h)
      end
    end

    @alive_snakes = @alive_snakes - dying_snakes
  end

  def tile_for(position)
    @world[position.y][position.x]
  end
end
