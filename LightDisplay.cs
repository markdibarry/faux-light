using Godot;
using GCol = Godot.Collections;

namespace FauxLight;

[Tool, GlobalClass]
public partial class LightDisplay : Node2D
{
    public LightDisplay()
    {
        var shader = new ShaderMaterial() { Shader = GD.Load<Shader>("res://shaders/faux_lights.gdshader") };
        shader.SetShaderParameter("ignore_scale", true);
        shader.SetShaderParameter("texture_mode", 2);
        shader.SetShaderParameter("alpha_mode", 2);
        _lightHub = new(shader);
        BackBufferCopy backBufferCopy = new() { CopyMode = BackBufferCopy.CopyModeEnum.Viewport };
        AddChild(backBufferCopy);
        AddChild(_lightHub);
    }

    [ExportGroup("Sources"), Export]
    public GCol.Array<LightSource?> Sources
    {
        get => _lightHub.Sources;
        set => _lightHub.Sources = value;
    }
    [Export]
    public Texture2D? Texture
    {
        get => _lightHub.Texture;
        set => _lightHub.Texture = value;
    }
    [ExportGroup("Dither"), Export(PropertyHint.Range, "0,1000")]
    public int QuantizeSize
    {
        get => _lightHub.QuantizeSize;
        set => _lightHub.QuantizeSize = value;
    }
    [Export(PropertyHint.Range, "1,16,1")]
    public int Divisions
    {
        get => _lightHub.Divisions;
        set => _lightHub.Divisions = value;
    }
    [Export(PropertyHint.Range, "1,3,1")]
    public int Pattern
    {
        get => _lightHub.Pattern;
        set => _lightHub.Pattern = value;
    }
    [Export]
    public bool Dither
    {
        get => _lightHub.Dither;
        set => _lightHub.Dither = value;
    }

    private LightMesh _lightHub;

    public override void _Ready()
    {
        MoveChild(_lightHub, -1);
        ChildEnteredTree += OnChildEnteredTree;

        if (!Engine.IsEditorHint())
        {
            //Engine.TimeScale = 0.2;
        }
    }

    private void OnChildEnteredTree(Node node)
    {
        if (_lightHub.GetIndex() != GetChildCount() - 1)
            CallDeferred(MethodName.MoveChild, _lightHub, -1);
    }

    public override bool _PropertyCanRevert(StringName property)
    {
        if (property == PropertyName.Dither ||
            property == PropertyName.Divisions ||
            property == PropertyName.Pattern ||
            property == PropertyName.QuantizeSize)
        {
            return true;
        }

        return base._PropertyCanRevert(property);
    }

    public override Variant _PropertyGetRevert(StringName property)
    {
        if (property == PropertyName.Dither)
            return false;
        else if (property == PropertyName.Divisions)
            return 1;
        else if (property == PropertyName.Pattern)
            return 1;
        else if (property == PropertyName.QuantizeSize)
            return 1;

        return base._PropertyGetRevert(property);
    }
}
