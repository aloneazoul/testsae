using System.Text;

namespace MBaumann.Iut.R6._6.TP1.ClassLib;

public class Board
{
    private readonly Random rand = new();

    public Board(int width, int height, int cellSize, bool wrap = true)
    {
        CellSize = cellSize;

        Cells = new Cell[width / cellSize, height / cellSize];
        for (var x = 0; x < Columns; x++)
        for (var y = 0; y < Rows; y++)
            Cells[x, y] = new Cell();

        for (var x = 0; x < Columns; x++)
        for (var y = 0; y < Rows; y++)
        {
            var isLeftEdge = x == 0;
            var isRightEdge = x == Columns - 1;
            var isTopEdge = y == 0;
            var isBottomEdge = y == Rows - 1;
            var isEdge = isLeftEdge | isRightEdge | isTopEdge | isBottomEdge;

            if (wrap == false && isEdge)
                continue;

            var xL = isLeftEdge ? Columns - 1 : x - 1;
            var xR = isRightEdge ? 0 : x + 1;
            var yT = isTopEdge ? Rows - 1 : y - 1;
            var yB = isBottomEdge ? 0 : y + 1;

            Cells[x, y].Neighbors.Add(Cells[xL, yT]);
            Cells[x, y].Neighbors.Add(Cells[x, yT]);
            Cells[x, y].Neighbors.Add(Cells[xR, yT]);
            Cells[x, y].Neighbors.Add(Cells[xL, y]);
            Cells[x, y].Neighbors.Add(Cells[xR, y]);
            Cells[x, y].Neighbors.Add(Cells[xL, yB]);
            Cells[x, y].Neighbors.Add(Cells[x, yB]);
            Cells[x, y].Neighbors.Add(Cells[xR, yB]);
        }
    }

    public Cell[,] Cells { get; }
    public int CellSize { get; }

    public int Columns => Cells.GetLength(0);

    public int Rows => Cells.GetLength(1);

    public int Width => Columns * CellSize;

    public int Height => Rows * CellSize;

    public void Randomize(double liveDensity)
    {
        foreach (var cell in Cells)
            cell.IsAlive = rand.NextDouble() < liveDensity;
    }

    public void Advance()
    {
        foreach (var cell in Cells)
        {
            cell.DetermineNextLiveState();
            cell.Advance();
        }

        foreach (var cell in Cells) ;
    }

    public void Reset(string startingPattern)
    {
        string[] lines = startingPattern.Split('\n');
        var yOffset = (Rows - lines.Length) / 2;
        var xOffset = (Columns - lines[0].Length) / 2;

        for (var y = 0; y < lines.Length; y++)
        for (var x = 0; x < lines[y].Length; x++)
            Cells[x + xOffset, y + yOffset].IsAlive = lines[y].Substring(x, 1) == "X";
    }

    public override string ToString()
    {
        var builder = new StringBuilder();

        for (var y = 0; y < Rows; y++)
        {
            for (var x = 0; x < Columns; x++) builder.Append(Cells[x, y]);

            if (y != Rows - 1)
                builder.Append('\n');
        }

        return builder.ToString();
    }
}