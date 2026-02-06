using NFluent;

namespace MBaumann.Iut.R6._6.TP1.ClassLib.Tests;

public class Integrations
{
    [Fact]
    public void Test1()
    {
        var board = new Board(5, 4, 1);

        Check.That(board.Width).Is(5);
        Check.That(board.Height).Is(4);
        Check.That(board.Columns).Is(5);
        Check.That(board.Rows).Is(4);
        Check.That(board.ToString()).Is("-----\n-----\n-----\n-----");

        board.Reset(spaceship);
        Check.That(board.ToString()).Is(spaceship);

        board.Advance();
        Check.That(board.ToString()).Is("X---X\n-----\n-----\n-----");

        board.Advance();
        Check.That(board.ToString()).Is("-----\n-----\n-----\n-----");

        board.Advance();
        Check.That(board.ToString()).Is("-----\n-----\n-----\n-----");
    }

    [Fact]
    public void Test2()
    {
        var board = new Board(10, 8, 2);

        Check.That(board.Width).Is(10);
        Check.That(board.Height).Is(8);
        Check.That(board.Columns).Is(5);
        Check.That(board.Rows).Is(4);
        Check.That(board.ToString()).Is("-----\n-----\n-----\n-----");

        board.Reset(spaceship);
        Check.That(board.ToString()).Is(spaceship);

        board.Advance();
        Check.That(board.ToString()).Is("X---X\n-----\n-----\n-----");

        board.Advance();
        Check.That(board.ToString()).Is("-----\n-----\n-----\n-----");

        board.Advance();
        Check.That(board.ToString()).Is("-----\n-----\n-----\n-----");
    }

    [Fact]
    public void Test3()
    {
        var board = new Board(36, 9, 1);

        Check.That(board.Width).Is(36);
        Check.That(board.Height).Is(9);
        Check.That(board.Columns).Is(36);
        Check.That(board.Rows).Is(9);

        board.Reset(gliderGun);
        Check.That(board.ToString()).Is(gliderGun);

        board.Advance();
        Check.That(board.ToString()).Is(
            "-----------------------X-X----------\n" +
            "---------------------X---X----------\n" +
            "-------------X-------X--------------\n" +
            "------------XXXX----X----X--------XX\n" +
            "-----------XX-X-X----X------------X-\n" +
            "-X--------XXX-X--X---X---X----------\n" +
            "XX---------XX-X-X------X-X----------\n" +
            "------------XXXX--------------------\n" +
            "-------------X----------------------");
    }

    [Fact]
    public void Test4()
    {
        var board = new Board(6, 6, 1);

        Check.That(board.Width).Is(6);
        Check.That(board.Height).Is(6);
        Check.That(board.Columns).Is(6);
        Check.That(board.Rows).Is(6);
        Check.That(board.ToString()).Is("------\n------\n------\n------\n------\n------");

        board.Reset(frog1);
        Check.That(board.ToString()).Is(frog1);

        for (var i = 0; i < 10_000; i++)
        {
            board.Advance();
            Check.That(board.ToString()).Is(frog2);

            board.Advance();
            Check.That(board.ToString()).Is(frog1);
        }
    }

    [Fact]
    public void Test5()
    {
        var board = new Board(4, 4, 1);

        Check.That(board.Width).Is(4);
        Check.That(board.Height).Is(4);
        Check.That(board.Columns).Is(4);
        Check.That(board.Rows).Is(4);
        Check.That(board.ToString()).Is("----\n----\n----\n----");

        board.Reset(block);
        Check.That(board.ToString()).Is(block);

        for (var i = 0; i < 10_000; i++)
        {
            board.Advance();
            Check.That(board.ToString()).Is(block);
        }
    }

    #region Patterns

    private readonly string spaceship =
        "--XX-\n-XXXX\nXX-XX\n-XX--";

    private readonly string gliderGun =
        "-------------------------X----------\n" +
        "----------------------XXXX----X-----\n" +
        "-------------X-------XXXX-----X-----\n" +
        "------------X-X------X--X---------XX\n" +
        "-----------X---XX----XXXX---------XX\n" +
        "XX---------X---XX-----XXXX----------\n" +
        "XX---------X---XX--------X----------\n" +
        "------------X-X---------------------\n" +
        "-------------X----------------------";

    private readonly string frog1 = "------\n------\n--XXX-\n-XXX--\n------\n------";
    private readonly string frog2 = "------\n---X--\n-X--X-\n-X--X-\n--X---\n------";

    private readonly string block = "----\n-XX-\n-XX-\n----";

    #endregion Patterns
}