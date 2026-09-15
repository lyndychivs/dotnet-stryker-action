namespace Sample.Unit.Tests;

using NUnit.Framework;

public class CalculatorTests
{
    [Test]
    public void Add_WithTwoPositiveNumbers_ReturnsThree()
    {
        Assert.That(Calculator.Add(1, 2), Is.EqualTo(3));
    }

    [Test]
    public void Add_WithPositiveAndNegativeNumbers_ReturnsZero()
    {
        Assert.That(Calculator.Add(1, -1), Is.EqualTo(0));
    }

    [Test]
    public void Add_WithZeroValues_ReturnsZero()
    {
        Assert.That(Calculator.Add(0, 0), Is.EqualTo(0));
    }

    [Test]
    public void Add_WithTwoNegativeNumbers_ReturnsNegativeThree()
    {
        Assert.That(Calculator.Add(-1, -2), Is.EqualTo(-3));
    }
}
