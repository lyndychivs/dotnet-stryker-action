namespace Sample.Unit.Tests;

public class CalculatorTests
{
    [Test]
    public void Add_returns_the_sum_of_both_values()
    {
        var sut = new global::Sample.Calculator();

        Assert.That(sut.Add(2, 3), Is.EqualTo(5));
    }
}
