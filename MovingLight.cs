using System;
using Godot;

namespace FauxLight;

public partial class MovingLight : LightSource
{
    [Export(PropertyHint.Range, "0.0, 50.0")]
    public float Distance { get; set; } = 10;
    [Export(PropertyHint.Range, "0.0, 5.0")]
    public float Duration { get; set; } = 2;
    [Export(PropertyHint.Range, "0.0, 1.0")]
    public float Offset { get; set; }
    private double Period => TwoPI / Duration;
    private double TimeWithOffset => _time + (Period * Offset);
    private const double TwoPI = 2 * Math.PI;
    private double _time;

    public override void _PhysicsProcess(double delta)
    {
        _time += (float)delta;

        if (_time >= Period * 100)
            _time -= Period * 100;

        float posX = (float)Math.Sin(TimeWithOffset * Period) * Distance;
        float posY = (float)Math.Sin(TimeWithOffset * Period * 2) * (Distance * 0.5f);
        Position = new Vector2(posX, posY);
    }
}
