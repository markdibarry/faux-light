using Godot;

namespace FauxLight;

[Tool, GlobalClass]
public partial class FauxLight : Sprite2D
{
    static FauxLight()
    {
        s_defaultTexture = GetDefaultTexture();
        string fileName = "res://shaders/faux_lights.gdshader";

        if (FileAccess.FileExists(fileName))
        {
            s_shader = new() { Shader = GD.Load<Shader>(fileName) };
            s_shader.SetShaderParameter(s_snapToWorldUniform, true);
        }
    }

    private static readonly ShaderMaterial s_shader = null!;
    private static readonly GradientTexture2D s_defaultTexture;
    private static readonly StringName s_maskUniform = "mask";
    private static readonly StringName s_fpsUniform = "fps";
    private static readonly StringName s_snapToWorldUniform = "snap_to_world";
    private static readonly StringName s_speedUniform = "speed";
    private static readonly StringName s_quantizeSizeUniform = "quantize_size";
    private static readonly StringName s_levelsUniform = "levels";
    private static readonly StringName s_ditherPatternUniform = "dither_pattern";
    private static readonly StringName s_ditherEnabledUniform = "dither_enabled";

    public FauxLight()
    {
        TextureFilter = TextureFilterEnum.Linear;
        Texture ??= s_defaultTexture;
        Material ??= s_shader;
    }

    private ShaderMaterial? Shader => Material as ShaderMaterial;

    [Export]
    public bool Mask
    {
        get;
        set
        {
            field = value;
            Shader?.SetShaderParameter(s_maskUniform, value);
        }
    }
    [Export]
    public int FPS
    {
        get;
        set
        {
            field = value;
            Shader?.SetShaderParameter(s_fpsUniform, value);
        }
    } = 10;
    [Export(PropertyHint.Range, "0.0, 5.0")]
    public float Speed
    {
        get;
        set
        {
            field = value;
            SetInstanceShaderParameter(s_speedUniform, value);
        }
    } = 0.25f;
    [Export]
    public bool Dither
    {
        get;
        set
        {
            field = value;
            Shader?.SetShaderParameter(s_ditherEnabledUniform, value);
        }
    }
    [Export(PropertyHint.Range, "0,1000")]
    public int QuantizeSize
    {
        get;
        set
        {
            field = value;
            Shader?.SetShaderParameter(s_quantizeSizeUniform, value);
        }
    } = 1;
    [Export(PropertyHint.Range, "2,16")]
    public int Levels
    {
        get;
        set
        {
            field = value;
            Shader?.SetShaderParameter(s_levelsUniform, value);
        }
    } = 2;
    [Export(PropertyHint.Range, "0,3,1")]
    public int Pattern
    {
        get;
        set
        {
            field = value;
            Shader?.SetShaderParameter(s_ditherPatternUniform, value);
        }
    } = 1;

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
