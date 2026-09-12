namespace Sample.Unit.Tests;

public class CalculatorTests
{
    [Test]
    public void Add_WithTwoPositiveNumbers_ReturnsFive()
    {
        Assert.That(Calculator.Add(2, 3), Is.EqualTo(5));
    }

    [Test]
    public void Add_WithPositiveAndNegativeNumbers_ReturnsOne()
    {
        Assert.That(Calculator.Add(3, -2), Is.EqualTo(1));
    }

    [Test]
    public void Add_WithZeroValues_ReturnsZero()
    {
        Assert.That(Calculator.Add(0, 0), Is.EqualTo(0));
    }

    [Test]
    public void Add_WithTwoNegativeNumbers_ReturnsNegativeFive()
    {
        Assert.That(Calculator.Add(-2, -3), Is.EqualTo(-5));
    }
}
