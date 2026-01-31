import pygame
from enum import IntEnum, unique
import math


@unique
class Piece(IntEnum):
    EMPTY = 0
    SOLDIER = 1
    CANNON = 2


@unique
class GameState(IntEnum):
    GAME_OVER = 0
    CANNONS_TURN = 1
    SOLDIERS_TURN = 2


SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
TILE_SIZE = 100
PIECE_RADIUS = TILE_SIZE // 2 - 3

# Initialize pygame
pygame.init()
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
pygame.display.set_caption("Three Cannons, Fifteen Soldiers")

# Colors
TEAL = (70, 153, 144)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
YELLOW = (255, 255, 0)
BEIGE = (245, 245, 220)

# Game variables
board = [[Piece.EMPTY for _ in range(5)] for _ in range(5)]
selected = (-1, -1)
gState = GameState.CANNONS_TURN
winner = Piece.EMPTY


def initialize_board():
    """Initialize the game board with pieces"""
    global board, selected, gState, winner

    # Clear board
    for y in range(5):
        for x in range(5):
            board[x][y] = Piece.EMPTY

    # Soldiers (15): Rows 0, 1, 2
    for y in range(3):
        for x in range(5):
            board[x][y] = Piece.SOLDIER

    # Cannons (3): Row 4
    board[1][4] = Piece.CANNON
    board[2][4] = Piece.CANNON
    board[3][4] = Piece.CANNON

    selected = (-1, -1)
    gState = GameState.CANNONS_TURN
    winner = Piece.EMPTY


def is_orthogonal_adjacent(x1, y1, x2, y2):
    """Check if two positions are orthogonally adjacent"""
    return (abs(x1 - x2) == 1 and y1 == y2) or (abs(y1 - y2) == 1 and x1 == x2)


def soldiers_less_than_three():
    """Check if there are less than 3 soldiers remaining"""
    count = 0
    for y in range(5):
        for x in range(5):
            if board[x][y] == Piece.SOLDIER:
                count += 1
    return count <= 3


def can_cannon_move():
    """Check if any cannon can move"""
    for y in range(5):
        for x in range(5):
            if board[x][y] == Piece.CANNON:
                # Check all four directions
                for dx, dy in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                    next_x, next_y = x + dx, y + dy
                    if 0 <= next_x <= 4 and 0 <= next_y <= 4:
                        if board[next_x][next_y] == Piece.EMPTY:
                            return True
    return False


def handle_click(grid_x, grid_y):
    """Handle mouse clicks on the game board"""
    global selected, gState, winner

    if selected == (-1, -1):
        # Select a piece if it's the current player's turn
        piece = board[grid_x][grid_y]
        if piece == Piece.EMPTY:
            return
        if (piece == Piece.CANNON) != (gState == GameState.CANNONS_TURN):
            return
        selected = (grid_x, grid_y)
    elif (grid_x == selected[0] and grid_y == selected[1]) or \
            not is_orthogonal_adjacent(selected[0], selected[1], grid_x, grid_y) or \
            board[grid_x][grid_y] != Piece.EMPTY:
        # Invalid movement, clear selection
        selected = (-1, -1)
    else:
        # Valid movement
        captured = False
        piece = board[selected[0]][selected[1]]

        if piece == Piece.CANNON:
            dx = math.copysign(
                1, grid_x - selected[0]) if grid_x != selected[0] else 0
            dy = math.copysign(
                1, grid_y - selected[1]) if grid_y != selected[1] else 0
            hop_x = selected[0] + dx
            hop_y = selected[1] + dy

            # Check if hop square is empty
            if board[int(hop_x)][int(hop_y)] == Piece.EMPTY:
                cap_x = hop_x + dx
                cap_y = hop_y + dy

                # Check if capture square is valid and has a soldier
                if 0 <= cap_x <= 4 and 0 <= cap_y <= 4:
                    if board[int(cap_x)][int(cap_y)] == Piece.SOLDIER:
                        # Capture the soldier
                        board[int(cap_x)][int(cap_y)] = Piece.CANNON
                        board[selected[0]][selected[1]] = Piece.EMPTY
                        captured = True

        if not captured:
            # Regular movement
            board[grid_x][grid_y] = board[selected[0]][selected[1]]
            board[selected[0]][selected[1]] = Piece.EMPTY

        selected = (-1, -1)

        # Switch turns
        gState = GameState.SOLDIERS_TURN if gState == GameState.CANNONS_TURN else GameState.CANNONS_TURN

        # Check game over conditions
        if soldiers_less_than_three():
            winner = Piece.CANNON
            gState = GameState.GAME_OVER
        elif gState == GameState.CANNONS_TURN and not can_cannon_move():
            winner = Piece.SOLDIER
            gState = GameState.GAME_OVER


def draw_board():
    """Draw the game board and pieces"""
    # Clear screen with teal background
    screen.fill(TEAL)

    # Draw grid lines
    for i in range(6):
        pygame.draw.line(screen, BLACK, (i * TILE_SIZE, 0),
                         (i * TILE_SIZE, 5 * TILE_SIZE), 1)
        pygame.draw.line(screen, BLACK, (0, i * TILE_SIZE),
                         (5 * TILE_SIZE, i * TILE_SIZE), 1)

    # Draw selection highlight
    if selected != (-1, -1):
        pygame.draw.rect(
            screen, YELLOW, (selected[0] * TILE_SIZE, selected[1] * TILE_SIZE, TILE_SIZE, TILE_SIZE), 2)

    # Draw clickable squares
    mark_clickable()

    # Draw pieces
    for y in range(5):
        for x in range(5):
            p = board[x][y]
            if p != Piece.EMPTY:
                center_x = (x + 0.5) * TILE_SIZE
                center_y = (y + 0.5) * TILE_SIZE
                color = RED if p == Piece.CANNON else BLUE

                # Draw piece
                pygame.draw.circle(
                    screen, color, (int(center_x), int(center_y)), PIECE_RADIUS)
                pygame.draw.circle(
                    screen, WHITE, (int(center_x), int(center_y)), PIECE_RADIUS - 10)
                pygame.draw.circle(
                    screen, color, (int(center_x), int(center_y)), PIECE_RADIUS - 20)

    # Draw status text
    font = pygame.font.SysFont("Lucida Console", 20)
    pygame.draw.rect(screen, WHITE, (5 * TILE_SIZE + 2, 2, 240, TILE_SIZE / 2))
    if gState != GameState.GAME_OVER:
        is_cannons_turn = (gState == GameState.CANNONS_TURN)
        color = RED if is_cannons_turn else BLUE
        message = "Cannons' Turn" if is_cannons_turn else "Soldiers' Turn"
        text_surface = font.render(message, True, color)
        screen.blit(text_surface, (5 * TILE_SIZE + 4, 4))
    else:
        color = RED if winner == Piece.CANNON else BLUE
        message = "CANNONS WIN!" if winner == Piece.CANNON else "SOLDIERS WIN!"
        text_surface = font.render(message, True, color)
        screen.blit(text_surface, (5 * TILE_SIZE + 4, 4))
        restart_text = font.render(
            f"{message} Press 'R' to start a new game.", True, BLACK)
        restart_rect = restart_text.get_rect(
            center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2))
        pygame.draw.rect(screen, BEIGE, restart_rect.inflate(20, 20))
        screen.blit(restart_text, restart_rect)

    instr_text = font.render(
        "Click on a piece to select it, then move it to a valid square.", True, WHITE)
    instr_text_rect = instr_text.get_rect(
        center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 50))
    screen.blit(instr_text, instr_text_rect)


def mark_clickable():
    """Highlight clickable squares"""
    if selected == (-1, -1):
        return

    piece = board[selected[0]][selected[1]]

    for dx, dy in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
        next_x, next_y = selected[0] + dx, selected[1] + dy

        if 0 <= next_x <= 4 and 0 <= next_y <= 4:
            if piece == Piece.SOLDIER:
                if board[next_x][next_y] == Piece.EMPTY:
                    pygame.draw.rect(screen, YELLOW,
                                     (next_x * TILE_SIZE + 2, next_y * TILE_SIZE + 2,
                                      TILE_SIZE - 4, TILE_SIZE - 4), 2)
            elif piece == Piece.CANNON:
                if board[next_x][next_y] == Piece.EMPTY:
                    pygame.draw.rect(screen, YELLOW,
                                     (next_x * TILE_SIZE + 2, next_y * TILE_SIZE + 2,
                                      TILE_SIZE - 4, TILE_SIZE - 4), 2)

                # Check for capture possibility
                hop_dx = math.copysign(1, dx) if dx != 0 else 0
                hop_dy = math.copysign(1, dy) if dy != 0 else 0
                hop_x = selected[0] + hop_dx
                hop_y = selected[1] + hop_dy

                if 0 <= hop_x <= 4 and 0 <= hop_y <= 4 and board[int(hop_x)][int(hop_y)] == Piece.EMPTY:
                    cap_x = hop_x + hop_dx
                    cap_y = hop_y + hop_dy

                    if 0 <= cap_x <= 4 and 0 <= cap_y <= 4 and board[int(cap_x)][int(cap_y)] == Piece.SOLDIER:
                        pygame.draw.circle(screen, YELLOW,
                                           ((int(hop_x) + 0.5) * TILE_SIZE, (int(hop_y) + 0.5) * TILE_SIZE), PIECE_RADIUS / 2, 2)


# Initialize the game board
initialize_board()

# Game loop
running = True
while running:
    # Handle events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            # Get mouse position and convert to grid coordinates
            mouse_x, mouse_y = pygame.mouse.get_pos()
            grid_x = mouse_x // TILE_SIZE
            grid_y = mouse_y // TILE_SIZE

            # Check if click is within the game board
            if 0 <= grid_x <= 4 and 0 <= grid_y <= 4:
                handle_click(grid_x, grid_y)
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                # Restart game
                initialize_board()
            elif event.key == pygame.K_ESCAPE:
                # Exit game
                running = False

    # Draw the game board
    draw_board()

    # Update the display
    pygame.display.flip()

# Clean up
pygame.quit()
