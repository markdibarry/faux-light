using Godot;

namespace FauxLight;

[Tool, GlobalClass]
public partial class FauxLight : Sprite2D
{
    private static readonly ShaderMaterial s_shader;
    private static readonly GradientTexture2D s_defaultTexture;

    static FauxLight()
    {
        s_defaultTexture = GetDefaultTexture();
        s_shader = new() { Shader = GD.Load<Shader>("res://shaders/faux_lights.gdshader") };
        s_shader.SetShaderParameter(SnapToWorldUniform, true);
    }

    public FauxLight()
    {
        TextureFilter = TextureFilterEnum.Linear;
        Texture ??= s_defaultTexture;
        Material ??= s_shader;
    }

    private static readonly StringName MaskUniform = "mask";
    private static readonly StringName FPSUniform = "fps";
    private static readonly StringName SnapToWorldUniform = "snap_to_world";
    private static readonly StringName SpeedUniform = "speed";
    private static readonly StringName QuantizeSizeUniform = "quantize_size";
    private static readonly StringName LevelsUniform = "levels";
    private static readonly StringName DitherPatternUniform = "dither_pattern";
    private static readonly StringName DitherEnabledUniform = "dither_enabled";

    [Export]
    public bool Mask
    {
        get => field;
        set
        {
            field = value;
            Shader?.SetShaderParameter(MaskUniform, value);
        }
    }
    [Export]
    public int FPS
    {
        get => field;
        set
        {
            field = value;
            Shader?.SetShaderParameter(FPSUniform, value);
        }
    } = 10;
    [Export(PropertyHint.Range, "0.0, 5.0")]
    public float Speed
    {
        get => field;
        set
        {
            field = value;
            SetInstanceShaderParameter(SpeedUniform, value);
        }
    } = 0.25f;
    [Export]
    public bool Dither
    {
        get => field;
        set
        {
            field = value;
            Shader?.SetShaderParameter(DitherEnabledUniform, value);
        }
    }
    [Export(PropertyHint.Range, "0,1000")]
    public int QuantizeSize
    {
        get => field;
        set
        {
            field = value;
            Shader?.SetShaderParameter(QuantizeSizeUniform, value);
        }
    } = 1;
    [Export(PropertyHint.Range, "2,16")]
    public int Levels
    {
        get => field;
        set
        {
            field = value;
            Shader?.SetShaderParameter(LevelsUniform, value);
        }
    } = 2;
    [Export(PropertyHint.Range, "0,3,1")]
    public int Pattern
    {
        get => field;
        set
        {
            field = value;
            Shader?.SetShaderParameter(DitherPatternUniform, value);
        }
    } = 1;

    private ShaderMaterial? Shader => Material as ShaderMaterial;

    /// <summary>
    /// Gets a default Gradient texture.
    /// </summary>
    /// <returns></returns>
    private static GradientTexture2D GetDefaultTexture()
    {
        return new()
        {
            Width = 50,
            Height = 50,
            Fill = GradientTexture2D.FillEnum.Radial,
            FillFrom = new(0.5f, 0.5f),
            FillTo = new(0.15f, 0.15f),
            Gradient = new Gradient()
            {
                Offsets = [0.5f, 1f],
                Colors =
                [
                    new(0, 0, 0, 1),
                    new(0, 0, 0, 0)
                ]
            }
        };
    }
}
