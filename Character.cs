using Godot;

namespace FauxLight;

public partial class Character : CharacterBody2D
{
    public const float Speed = 100.0f;
    public const float JumpVelocity = -300.0f;

    // Get the gravity from the project settings to be synced with RigidBody nodes.
    public float gravity = ProjectSettings.GetSetting("physics/2d/default_gravity").AsSingle();
    private AnimatedSprite2D _animatedSprite2D = null!;

    public override void _Ready()
    {
        _animatedSprite2D = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
    }

    public override void _PhysicsProcess(double delta)
    {
        Vector2 velocity = Velocity;

        // Add the gravity.
        if (!IsOnFloor())
            velocity.Y += gravity * (float)delta;

        // Handle Jump.
        if (Input.IsActionJustPressed("ui_accept") && IsOnFloor())
            velocity.Y = JumpVelocity;

        // Get the input direction and handle the movement/deceleration.
        // As good practice, you should replace UI actions with custom gameplay actions.
        Vector2 direction = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");

        if (direction != Vector2.Zero)
        {
            _animatedSprite2D.Play("Walk");
            velocity.X = direction.X * Speed;

            if (direction < Vector2.Zero)
                _animatedSprite2D.FlipH = true;
            else if (direction > Vector2.Zero)
                _animatedSprite2D.FlipH = false;
        }
        else
        {
            _animatedSprite2D.Play("default");
            velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
        }

        Velocity = velocity;
        MoveAndSlide();
    }
}
