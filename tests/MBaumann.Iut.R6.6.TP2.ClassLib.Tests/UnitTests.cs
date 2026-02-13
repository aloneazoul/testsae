using NFluent;

namespace MBaumann.Iut.R6._6.TP2.ClassLib.Tests
{
    public class UnitTests
    {
        [Theory]
        [InlineData("0", "zéro euro")]
        [InlineData("0,5", "cinquante centimes")]
        [InlineData("0,50", "cinquante centimes")]
        [InlineData("1", "un euro")]
        [InlineData("2", "deux euros")]
        [InlineData("2,75", "deux euros et soixante-quinze centimes")]
        [InlineData("200", "deux cents euros")]
        [InlineData("4192", "quatre mille cent quatre-vingt-douze euros")]
        [InlineData("296375737682,14", "deux cent quatre-vingt-seize milliards trois cent soixante-quinze millions sept cent trente-sept mille six cent quatre-vingt-deux euros et quatorze centimes")]
        public void Tests(string input, string expected)
        {
            var parser = new Parser();

            Check.That(parser.Parse(input)).Is(expected);
        }

        [Theory]
        [InlineData("0,")]
        [InlineData("0,137")]
        [InlineData("0.13")]
        public void ExceptionTests(string input)
        {
            var parser = new Parser();

            Check.ThatCode(() => parser.Parse(input)).Throws<Parser.InputFormatException>();
        }
    }
}