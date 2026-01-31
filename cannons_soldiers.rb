require 'ruby2d'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
TILE_SIZE = 100
PIECE_RADIUS = TILE_SIZE / 2 - 3

set(
  title: "Three Cannons, Fifteen Soldiers",
  width: SCREEN_WIDTH,
  height: SCREEN_HEIGHT
)

# Enumerations
module Piece
  EMPTY = 0
  SOLDIER = 1
  CANNON = 2
end

module GameState
  GAME_OVER = 0
  CANNONS_TURN = 1
  SOLDIERS_TURN = 2
end

# Game variables
@board = Array.new(5) { Array.new(5, Piece::EMPTY) }
@selected = [-1, -1]
@g_state = GameState::CANNONS_TURN
@winner = Piece::EMPTY

# Game state variables for drawing
@selection_rect = nil
@highlighted_tiles = []
@status_text = nil
@restart_text = nil
@instruction_text = nil


def initialize_board
  """Initialize the game board with pieces"""
  # Clear board
  @board = Array.new(5) { Array.new(5, Piece::EMPTY) }
  
  # Soldiers (15): Rows 0, 1, 2
  (0..2).each do |y|
    (0..4).each do |x|
      @board[x][y] = Piece::SOLDIER
    end
  end
  
  # Cannons (3): Row 4
  @board[1][4] = Piece::CANNON
  @board[2][4] = Piece::CANNON
  @board[3][4] = Piece::CANNON
  
  @selected = [-1, -1]
  @g_state = GameState::CANNONS_TURN
  @winner = Piece::EMPTY
  
  # Clear drawing objects
  @highlighted_tiles = []
  @selection_rect = nil
  @status_text = nil
  @restart_text = nil
  @instruction_text = nil
end


def is_orthogonal_adjacent(x1, y1, x2, y2)
  """Check if two positions are orthogonally adjacent"""
  (x1 - x2).abs == 1 && y1 == y2 || (y1 - y2).abs == 1 && x1 == x2
end


def soldiers_less_than_three
  """Check if there are less than 3 soldiers remaining"""
  count = 0
  (0..4).each do |y|
    (0..4).each do |x|
      count += 1 if @board[x][y] == Piece::SOLDIER
    end
  end
  count <= 3
end


def can_cannon_move
  """Check if any cannon can move"""
  (0..4).each do |y|
    (0..4).each do |x|
      if @board[x][y] == Piece::CANNON
        # Check all four directions
        [[0, 1], [0, -1], [1, 0], [-1, 0]].each do |dx, dy|
          next_x, next_y = x + dx, y + dy
          if next_x.between?(0, 4) && next_y.between?(0, 4)
            return true if @board[next_x][next_y] == Piece::EMPTY
          end
        end
      end
    end
  end
  false
end


def handle_click(grid_x, grid_y)
  """Handle mouse clicks on the game board"""
  if @selected == [-1, -1]
    # Select a piece if it's the current player's turn
    piece = @board[grid_x][grid_y]
    return if piece == Piece::EMPTY
    return if (piece == Piece::CANNON) != (@g_state == GameState::CANNONS_TURN)
    @selected = [grid_x, grid_y]
  elsif (grid_x == @selected[0] && grid_y == @selected[1]) ||
        !is_orthogonal_adjacent(@selected[0], @selected[1], grid_x, grid_y) ||
        @board[grid_x][grid_y] != Piece::EMPTY
    # Invalid movement, clear selection
    @selected = [-1, -1]
  else
    # Valid movement
    captured = false
    piece = @board[@selected[0]][@selected[1]]
    
    if piece == Piece::CANNON
      sign = ->(x) { x.zero? ? 0 : x / x.abs }
      dx = grid_x != @selected[0] ? sign.call(grid_x - @selected[0]) : 0
      dy = grid_y != @selected[1] ? sign.call(grid_y - @selected[1]) : 0
      hop_x = @selected[0] + dx
      hop_y = @selected[1] + dy
      
      # Check if hop square is empty
      if @board[hop_x][hop_y] == Piece::EMPTY
        cap_x = hop_x + dx
        cap_y = hop_y + dy
        
        # Check if capture square is valid and has a soldier
        if cap_x.between?(0, 4) && cap_y.between?(0, 4)
          if @board[cap_x][cap_y] == Piece::SOLDIER
            # Capture the soldier
            @board[cap_x][cap_y] = Piece::CANNON
            @board[@selected[0]][@selected[1]] = Piece::EMPTY
            captured = true
          end
        end
      end
    end
    
    if !captured
      # Regular movement
      @board[grid_x][grid_y] = @board[@selected[0]][@selected[1]]
      @board[@selected[0]][@selected[1]] = Piece::EMPTY
    end
    
    @selected = [-1, -1]
    
    # Switch turns
    @g_state = @g_state == GameState::CANNONS_TURN ? GameState::SOLDIERS_TURN : GameState::CANNONS_TURN
    
    # Check game over conditions
    if soldiers_less_than_three
      @winner = Piece::CANNON
      @g_state = GameState::GAME_OVER
    elsif @g_state == GameState::CANNONS_TURN && !can_cannon_move
      @winner = Piece::SOLDIER
      @g_state = GameState::GAME_OVER
    end
  end
end


def draw_board
  """Draw the game board and pieces"""
  # Clear previous frames
  clear
  
  # Draw background
  Rectangle.new(
    x: 0,
    y: 0,
    width: SCREEN_WIDTH,
    height: SCREEN_HEIGHT,
    color: 'teal'
  )
  
  # Draw grid lines
  (0..5).each do |i|
    Line.new(
      x1: i * TILE_SIZE,
      y1: 0,
      x2: i * TILE_SIZE,
      y2: 5 * TILE_SIZE,
      color: 'black',
      width: 1
    )
    Line.new(
      x1: 0,
      y1: i * TILE_SIZE,
      x2: 5 * TILE_SIZE,
      y2: i * TILE_SIZE,
      color: 'black',
      width: 1
    )
  end
  
  # Draw selection highlight
  if @selected != [-1, -1]
    Square.new(
      x: @selected[0] * TILE_SIZE,
      y: @selected[1] * TILE_SIZE,
      size: TILE_SIZE,
      color: 'yellow'
    )
  end
  
  # Draw clickable squares
  mark_clickable
  
  # Draw pieces
  (0..4).each do |y|
    (0..4).each do |x|
      p = @board[x][y]
      if p != Piece::EMPTY
        center_x = (x + 0.5) * TILE_SIZE
        center_y = (y + 0.5) * TILE_SIZE
        color = p == Piece::CANNON ? 'red' : 'blue'
        
        # Draw piece
        Circle.new(
          x: center_x,
          y: center_y,
          radius: PIECE_RADIUS,
          color: color
        )
        Circle.new(
          x: center_x,
          y: center_y,
          radius: PIECE_RADIUS - 10,
          color: 'white'
        )
        Circle.new(
          x: center_x,
          y: center_y,
          radius: PIECE_RADIUS - 20,
          color: color
        )
      end
    end
  end
  
  # Draw status text
  status_bg = Rectangle.new(
    x: 5 * TILE_SIZE + 2,
    y: 2,
    width: 240,
    height: TILE_SIZE / 2,
    color: 'white'
  )
  
  if @g_state != GameState::GAME_OVER
    is_cannons_turn = (@g_state == GameState::CANNONS_TURN)
    color = is_cannons_turn ? 'red' : 'blue'
    message = is_cannons_turn ? "Cannons' Turn" : "Soldiers' Turn"
    Text.new(
      message,
      x: 5 * TILE_SIZE + 4,
      y: 4,
      color: color,
      font: Font.default,
      size: 20
    )
  else
    color = @winner == Piece::CANNON ? 'red' : 'blue'
    message = @winner == Piece::CANNON ? "CANNONS WIN!" : "SOLDIERS WIN!"
    Text.new(
      message,
      x: 5 * TILE_SIZE + 4,
      y: 4,
      color: color,
      font: Font.default,
      size: 20
    )
    
    # Create restart message as a placeholder - will be redrawn immediately
    restart_msg = "#{message} Press 'R' to start a new game."
    restart_text = Text.new(
      restart_msg,
      x: SCREEN_WIDTH,
      y: SCREEN_HEIGHT,
      color: 'teal',
      font: Font.default,
      size: 20
    )
    
    # Calculate text dimensions for background
    text_width = restart_text.width
    text_height = restart_text.height
    
    # Draw background rectangle
    Rectangle.new(
      x: (SCREEN_WIDTH / 2) - (text_width / 2) - 20,
      y: (SCREEN_HEIGHT / 2) - (text_height / 2) - 20,
      width: text_width + 40,
      height: text_height + 40,
      color: 'green'
    )
    
    # Redraw text on top of background
    Text.new(
      restart_msg,
      x: (SCREEN_WIDTH / 2) - (text_width / 2),
      y: (SCREEN_HEIGHT / 2) - (text_height / 2),
      color: 'white',
      font: Font.default,
      size: 20
    )
  end
  
  # Draw instructions
  Text.new(
    "How to Play: Click on a piece to select it, then move it to a valid square.",
    x: 50,
    y: SCREEN_HEIGHT - 50,
    color: 'black',
    font: Font.default,
    size: 20
  )
end


def mark_clickable
  """Highlight clickable squares"""
  return if @selected == [-1, -1]
  
  piece = @board[@selected[0]][@selected[1]]
  
  [[0, 1], [0, -1], [1, 0], [-1, 0]].each do |dx, dy|
    next_x, next_y = @selected[0] + dx, @selected[1] + dy
    
    if next_x.between?(0, 4) && next_y.between?(0, 4)
      if piece == Piece::SOLDIER
        if @board[next_x][next_y] == Piece::EMPTY
          Square.new(
            x: next_x * TILE_SIZE + 2,
            y: next_y * TILE_SIZE + 2,
            size: TILE_SIZE - 4,
            color: 'yellow'
          )
        end
      elsif piece == Piece::CANNON
        if @board[next_x][next_y] == Piece::EMPTY
          Square.new(
            x: next_x * TILE_SIZE + 2,
            y: next_y * TILE_SIZE + 2,
            size: TILE_SIZE - 4,
            color: 'yellow'
          )
        end
        
        # Check for capture possibility
        sign = ->(x) { x.zero? ? 0 : x / x.abs }
        hop_dx = dx != 0 ? sign.call(dx) : 0
        hop_dy = dy != 0 ? sign.call(dy) : 0
        hop_x = @selected[0] + hop_dx
        hop_y = @selected[1] + hop_dy
        
        if hop_x.between?(0, 4) && hop_y.between?(0, 4) && @board[hop_x][hop_y] == Piece::EMPTY
          cap_x = hop_x + hop_dx
          cap_y = hop_y + hop_dy
          
          if cap_x.between?(0, 4) && cap_y.between?(0, 4) && @board[cap_x][cap_y] == Piece::SOLDIER
            Circle.new(
              x: (hop_x + 0.5) * TILE_SIZE,
              y: (hop_y + 0.5) * TILE_SIZE,
              radius: PIECE_RADIUS / 2,
              color: 'orange'
            )
          end
        end
      end
    end
  end
end


# Initialize the game board
initialize_board

# Mouse click handling
on :mouse_down do |event|
  if event.button == :left
    # Get mouse position and convert to grid coordinates
    grid_x = event.x / TILE_SIZE
    grid_y = event.y / TILE_SIZE
    
    # Check if click is within the game board
    if grid_x.between?(0, 4) && grid_y.between?(0, 4)
      handle_click(grid_x, grid_y)
    end
  end
end

# Keyboard handling
on :key_down do |event|
  if event.key == "r"
    # Restart game
    initialize_board
  elsif event.key == "escape"
    # Exit game
    exit
  end
end

# Update loop
update do
  draw_board
end

# Start the game
if __FILE__ == $0
  show
end