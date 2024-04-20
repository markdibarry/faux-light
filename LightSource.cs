using Godot;
using System;

namespace FauxLight;

[Tool, GlobalClass]
public partial class LightSource : Node2D
{
    public LightSource()
    {
        SetNotifyTransform(true);
    }

    [Export]
    public int MaxSize
    {
        get => _maxSize;
        set
        {
            _maxSize = value;
            GlobalPositionChanged?.Invoke(this);
        }
    }
    [Export(PropertyHint.Range, "0.0, 5.0")]
    public float Speed
    {
        get => _speed;
        set
        {
            _speed = value;
            GlobalPositionChanged?.Invoke(this);
        }
    }
    public event Action<LightSource>? GlobalPositionChanged;
    public event Action<LightSource>? Parented;
    public event Action<LightSource>? Unparented;
    public event Action<LightSource>? Deleted;
    public event Action<LightSource>? VisibilityUpdated;

    private int _maxSize = 100;
    private float _speed = 0.25f;

    public override void _Notification(int what)
    {
        switch ((long)what)
        {
            case NotificationParented:
                Parented?.Invoke(this);
                CallDeferred(MethodName.ResetPosition);
                break;
            case NotificationTransformChanged:
                GlobalPositionChanged?.Invoke(this);
                break;
            case NotificationUnparented:
                Unparented?.Invoke(this);
                break;
            case NotificationPredelete:
                Deleted?.Invoke(this);
                break;
            case NotificationVisibilityChanged:
                VisibilityUpdated?.Invoke(this);
                break;
        }
    }

    private void ResetPosition()
    {
        Position = Vector2.Zero;
    }
}
