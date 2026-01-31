Imports VbPixelGameEngine

Public NotInheritable Class Program
    Inherits PixelGameEngine

    Private Enum Piece
        Empty = 0
        Soldier = 1
        Cannon = 2
    End Enum

    Private Enum GameState
        GameOver = 0
        CannonsTurn = 1
        SoldiersTurn = 2
    End Enum

    Private ReadOnly board(4, 4) As Piece          ' 5x5 grid
    Private selected As (x As Integer, y As Integer) = (-1, -1)
    Private gState As GameState = GameState.CannonsTurn
    Private winner As Piece

    Private Const TILE_SIZE As Integer = 32

    Public Sub New()
        AppName = "Three Cannons, Fifteen Soldiers"
    End Sub

    Protected Overrides Function OnUserCreate() As Boolean
        Array.Clear(board, 0, board.Length)

        ' Soldiers (15): Rows 0,1,2
        For y As Integer = 0 To 2
            For x As Integer = 0 To 4
                board(x, y) = Piece.Soldier
            Next x
        Next y

        ' Cannons (3): Row 4
        board(1, 4) = Piece.Cannon
        board(2, 4) = Piece.Cannon
        board(3, 4) = Piece.Cannon

        selected = (-1, -1)
        gState = GameState.CannonsTurn
        winner = Piece.Empty

        Return True
    End Function

    Protected Overrides Function OnUserUpdate(elapsed As Single) As Boolean
        ' Mouse handling
        Dim gridX As Integer = GetMouseX() \ TILE_SIZE
        Dim gridY As Integer = GetMouseY() \ TILE_SIZE

        If GetMouse(0).Released AndAlso gridX >= 0 AndAlso gridX <= 4 AndAlso
            gridY >= 0 AndAlso gridY <= 4 Then HandleClick(gridX, gridY)

        DrawBoard()
        If GetKey(Key.R).Pressed Then Call OnUserCreate()
        Return Not GetKey(Key.ESCAPE).Pressed
    End Function

    Private Sub HandleClick(x As Integer, y As Integer)
        If selected.x = -1 Then
            Dim piece = board(x, y)
            If piece = Piece.Empty Then Exit Sub
            If (piece = Piece.Cannon) <> (gState = GameState.CannonsTurn) Then Exit Sub
            selected = (x, y)
        ElseIf (x = selected.x AndAlso y = selected.y) OrElse
            Not IsOrthogonalAdjacent(selected.x, selected.y, x, y) OrElse
            board(x, y) <> Piece.Empty Then
            ' Invaild movement falls back to the unselected state
            selected = (-1, -1)
            Exit Sub
        Else
            ' Cannon must check capture possibility first
            Dim captured As Boolean = False
            With selected
                If board(.x, .y) = Piece.Cannon Then
                    Dim dx = Math.Sign(x - .x)
                    Dim dy = Math.Sign(y - .y)
                    Dim hopX = .x + dx
                    Dim hopY = .y + dy
                    ' Hop must be empty
                    If board(hopX, hopY) = Piece.Empty Then
                        Dim capX = hopX + dx
                        Dim capY = hopY + dy
                        If capX >= 0 AndAlso capX <= 4 AndAlso capY >= 0 AndAlso
                           capY <= 4 AndAlso board(capX, capY) = Piece.Soldier Then
                            board(capX, capY) = Piece.Cannon
                            board(.x, .y) = Piece.Empty
                            captured = True
                        End If
                    End If
                End If
                If Not captured Then
                    board(x, y) = board(.x, .y)
                    board(.x, .y) = Piece.Empty
                End If
            End With

            selected = (-1, -1)
            gState = If(
                gState = GameState.CannonsTurn, GameState.SoldiersTurn, GameState.CannonsTurn
            )

            If SoldiersLessThanThree() Then
                winner = Piece.Cannon
                gState = GameState.GameOver
            ElseIf gState = GameState.CannonsTurn AndAlso Not CanCannonMove() Then
                winner = Piece.Soldier
                gState = GameState.GameOver
            End If
        End If
    End Sub

    Private Shared Function IsOrthogonalAdjacent _
            (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As Boolean
        Return (Math.Abs(x1 - x2) = 1 AndAlso y1 = y2) OrElse
               (Math.Abs(y1 - y2) = 1 AndAlso x1 = x2)
    End Function

    Private Function SoldiersLessThanThree() As Boolean
        Dim count As Integer = 0
        For y As Integer = 0 To 4
            For x As Integer = 0 To 4
                If board(x, y) = Piece.Soldier Then count += 1
            Next x
        Next y
        Return count <= 3
    End Function

    Private Function CanCannonMove() As Boolean
        For y As Integer = 0 To 4
            For x As Integer = 0 To 4
                If board(x, y) = Piece.Cannon Then
                    ' Four directions
                    For Each dir As (Integer, Integer) In {(0, 1), (0, -1), (1, 0), (-1, 0)}
                        Dim nextX = x + dir.Item1
                        Dim nextY = y + dir.Item2
                        If nextX < 0 OrElse nextY < 0 OrElse nextX > 4 OrElse nextY > 4 _
                            OrElse board(nextX, nextY) <> Piece.Empty Then Continue For
                        Return True
                    Next dir
                End If
            Next x
        Next y
        Return False
    End Function

    Private Sub DrawBoard()
        Clear(Presets.Teal)

        ' Draw grid first
        For i As Integer = 0 To 5
            DrawLine(0, i * TILE_SIZE, 5 * TILE_SIZE, i * TILE_SIZE, Presets.Black)
            DrawLine(i * TILE_SIZE, 0, i * TILE_SIZE, 5 * TILE_SIZE, Presets.Black)
        Next i
        ' Draw selection highlight
        If selected.x <> -1 Then
            Dim gridX = selected.x * TILE_SIZE
            Dim gridY = selected.y * TILE_SIZE
            DrawRect(gridX, gridY, TILE_SIZE, TILE_SIZE, Presets.Yellow)
        End If
        MarkClickable()

        ' Draw pieces
        For y As Integer = 0 To 4
            For x As Integer = 0 To 4
                Dim p = board(x, y)
                If p <> Piece.Empty Then
                    Dim centerX = (x + 0.5F) * TILE_SIZE
                    Dim centerY = (y + 0.5F) * TILE_SIZE
                    Dim color = If(p = Piece.Cannon, Presets.Red, Presets.Blue)
                    FillCircle(centerX, centerY, 12, color)
                    FillCircle(centerX, centerY, 8, Presets.White)
                    FillCircle(centerX, centerY, 6, color)
                End If
            Next x
        Next y

        FillRect(5 * TILE_SIZE + 2, 2, 115, 16, Presets.White)
        If gState <> GameState.GameOver Then
            Dim isCannonsTurn = (gState = GameState.CannonsTurn)
            Dim color = If(isCannonsTurn, Presets.Red, Presets.Blue)
            Dim message = If(isCannonsTurn, "Cannons' Turn", "Soldiers' Turn")
            DrawString(5 * TILE_SIZE + 4, 4, message, color, 1)
        Else
            Dim color = If(winner = Piece.Cannon, Presets.Red, Presets.Blue)
            Dim message = If(winner = Piece.Cannon, "CANNONS WIN!", "SOLDIERS WIN!")
            DrawString(5 * TILE_SIZE + 4, 4, message, color, 1)
            FillRect(5, TILE_SIZE * 2 + 5, ScreenWidth - 20, TILE_SIZE - 10, Presets.Beige)
            DrawString(10, TILE_SIZE * 2 + 10, $"Press 'R' to start a new game.", Presets.Black)
        End If
    End Sub

    Private Sub MarkClickable()
        Dim DrawHighlight = Sub(x As Integer, y As Integer) _
            DrawRect(x * TILE_SIZE + 2, y * TILE_SIZE + 2, TILE_SIZE - 4, TILE_SIZE - 4,
                     Presets.Yellow)

        If selected.x = -1 Then Exit Sub
        Dim piece = board(selected.x, selected.y)

        For Each dir As (Integer, Integer) In {(0, 1), (0, -1), (1, 0), (-1, 0)}
            Dim nextX = selected.x + dir.Item1
            Dim nextY = selected.y + dir.Item2
            If nextX < 0 OrElse nextY < 0 OrElse nextX > 4 OrElse nextY > 4 Then Continue For

            Select Case piece
                Case Piece.Soldier
                    If board(nextX, nextY) = Piece.Empty Then DrawHighlight(nextX, nextY)
                Case Piece.Cannon
                    If board(nextX, nextY) = Piece.Empty Then DrawHighlight(nextX, nextY)
                    Dim dx = Math.Sign(nextX - selected.x)
                    Dim dy = Math.Sign(nextY - selected.y)
                    Dim hopX = selected.x + dx
                    Dim hopY = selected.y + dy
                    If hopX >= 0 AndAlso hopX <= 4 AndAlso hopY >= 0 AndAlso hopY <= 4 AndAlso
                        hopX + dx >= 0 AndAlso hopX + dx <= 4 AndAlso hopY + dy >= 0 AndAlso
                        hopY + dy <= 4 AndAlso board(hopX, hopY) = Piece.Empty AndAlso
                        board(hopX + dx, hopY + dy) = Piece.Soldier Then DrawCircle(
                        (hopX + 0.5F) * TILE_SIZE, (hopY + 0.5F) * TILE_SIZE, 8, Presets.Yellow)
            End Select
        Next dir
    End Sub

    Friend Shared Sub Main()
        With New Program
            If .Construct(5 * TILE_SIZE + 120, 5 * TILE_SIZE, fullScreen:=True) Then .Start()
        End With
    End Sub
End Class