namespace MBaumann.Iut.R6._6.TP1.ClassLib;

public class Cell
{
    public bool IsAlive { get; set; }
    public bool IsAliveNext { get; set; }
    public IList<Cell> Neighbors { get; } = new List<Cell>();

    public void DetermineNextLiveState()
    {
        var liveNeighbors = Neighbors.ToList().Where(x => x.IsAlive).Count();

        if (IsAlive)
        {
            // Chaque cellule vivante avec moins de deux voisins meurt
            if (liveNeighbors < 2)
                IsAliveNext = false;
            // Chaque cellule vivante avec plus de deux voisins meurt
            else if (liveNeighbors > 3)
                IsAliveNext = false;
            // Chaque cellule vivante avec deux ou trois voisins reste en vie
            else
                IsAliveNext = true;
        }
        else
        {
            // Chaque cellule morte avec trois voisins revient à la vie
            if (liveNeighbors == 3)
                IsAliveNext = true;
            // Les autres cellules restent mortes
            else
                IsAliveNext = false;
        }
    }

    public void Advance()
    {
        IsAlive = IsAliveNext;
    }

    public override string ToString()
    {
        return IsAlive ? "X" : "-";
    }
}