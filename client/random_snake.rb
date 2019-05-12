class RandomSnake
  def initialize(our_snake, game_state, map)
    # Game state is an hash with the following structure
    # {
    #   alive_snakes: [{snake}],
    #   leaderboard: []
    # }
    # Each snake is made up of the following:
    # {
    #   id: id,
    #   name: name,
    #   head: {x: <int>, y: <int>,
    #   color: <string>,
    #   length: <int>,
    #   body: [{x: <int>, y: <int>}, etc.]
    # }
    @game_state = game_state.deep_symbolize_keys
    #puts @game_state.inspect
    # Map is a 2D array of chars.  # represents a wall and '.' is a blank tile.
    # The map is fetched once - it does not include snake positions - that's in game state.
    # The map uses [y][x] for coords so @map[0][0] would represent the top left most tile
    @map = map
    @our_snake = our_snake
    #@our_snake_last_move = last_move
    @our_snake_current_position = @our_snake.fetch(:head)
    @our_snake_current_position_y = @our_snake_current_position.fetch(:y)
    @our_snake_current_position_x = @our_snake_current_position.fetch(:x)
    @our_snake_body = @our_snake.fetch(:body)
    @all_snakes = @game_state.fetch(:alive_snakes)

    @all_snake_heads = []
    @all_snake_bodies = []
    
    @all_snakes.each do |snake|
      if snake.fetch(:id) != @our_snake.fetch(:id)
        @all_snake_heads << snake.fetch(:head)
      end

      snake.fetch(:body).each do |snake_body_location|
        @all_snake_bodies << snake_body_location
      end
    end

    @all_snake_locations = @all_snake_heads + @all_snake_bodies
    @unsafe_locations = []

    @all_snake_locations.each do |snake_location|
      snake_location_y = snake_location.fetch(:y)
      snake_location_x = snake_location.fetch(:x)

      @unsafe_locations << {"y" => snake_location_y, "x" => snake_location_x + 1}
      @unsafe_locations << {"y" => snake_location_y, "x" => snake_location_x - 1}
      @unsafe_locations << {"y" => snake_location_y, "x" => snake_location_x}
      @unsafe_locations << {"y" => snake_location_y + 1, "x" => snake_location_x}
      @unsafe_locations << {"y" => snake_location_y - 1, "x" => snake_location_x}
    end

  end

  def get_intent
    # Let's evaluate a random move
    possible_moves = ["N", "E", "W", "S"]
    puts "1" + possible_moves.to_s
    # Rejecting possible moves that would bump into unsafe locations
    possible_moves.reject!{|possible_intent|
      @unsafe_locations.include?(next_position(possible_intent).with_indifferent_access)
    }

    puts "2" + possible_moves.to_s
    # Rejecting possible moves that would bump into walls
    possible_moves.reject!{|possible_intent|

      case possible_intent
      when 'N'
        #reject if something is blocking in North Side
        next_north = @map[@our_snake_current_position_y - 1][@our_snake_current_position_x]
        case next_north
        when '#'
          true
        else
          false
      end
      when 'E'
        #reject if something is blocking in East Side
        next_east = @map[@our_snake_current_position_y ][@our_snake_current_position_x + 1]
        case next_east
        when '#'
          true
        else
          false
        end
      when 'W'
        #reject if something is blocking in West Side
        next_west = @map[@our_snake_current_position_y ][@our_snake_current_position_x - 1]
        case next_west
        when '#'
          true
        else
          false
        end
      when 'S'
        #reject if something is blocking in South Side
        next_south = @map[@our_snake_current_position_y  + 1][@our_snake_current_position_x]
        case next_south
        when '#'
          true
        else
          false
        end
      end
    }
    puts "3" + possible_moves.to_s
    if possible_moves.empty?
      # Doh - we're dead anyway
      "N"
    else
      #if (@our_snake_last_move !=nil && possible_moves.include?(@our_snake_last_move))
      #  @our_snake_last_move
      #  puts "Making the same move as last time " + @our_snake_last_move.to_s
      #else
      possible_moves.first
      #  puts "Making the first of the possible moves " + possible_moves.first.to_s
      #end
    end
  end

  private

  def next_position(possible_intent)
    case possible_intent
    when 'N' then {"y" => @our_snake_current_position_y  - 1, "x" => @our_snake_current_position_x}
    when 'S' then {"y" => @our_snake_current_position_y  + 1, "x" => @our_snake_current_position_x}
    when 'E' then {"y" => @our_snake_current_position_y ,     "x" => @our_snake_current_position_x + 1}
    when 'W' then {"y" => @our_snake_current_position_y ,     "x" => @our_snake_current_position_x - 1}
    end.with_indifferent_access
  end


end