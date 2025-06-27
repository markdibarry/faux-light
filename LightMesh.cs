using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using GCol = Godot.Collections;

namespace FauxLight;

[Tool]
public partial class LightMesh : MultiMeshInstance2D
{
    public LightMesh()
    {
        _shader ??= new ShaderMaterial() { Shader = GD.Load<Shader>("res://shaders/dither_main.gdshader") };
        _shader.SetShaderParameter("snap_to_world", true);
        _quadMesh = new() { Size = new(MeshSize, -MeshSize) };
        _multiMesh = new() { Mesh = _quadMesh, UseCustomData = true };
        QuantizeSize = _quantizeSize;
        Dither = _dither;
        Levels = _levels;
        Pattern = _pattern;
        Texture ??= GetDefaultTexture();
        Sources = [];
    }

    public LightMesh(ShaderMaterial shader) : this()
    {
        _shader = shader;
    }

    private static readonly StringName QuantizeSizeUniform = "quantize_size";
    private static readonly StringName LevelsUniform = "levels";
    private static readonly StringName DitherPatternUniform = "dither_pattern";
    private static readonly StringName DitherEnabledUniform = "dither_enabled";

    [ExportGroup("Sources"), Export]
    public GCol.Array<LightSource?> Sources
    {
        get => field;
        set
        {
            if (value.Count != value.Distinct().Count())
                return;

            Reset(value);
            field = value;
        }
    }
    [ExportGroup("Dither"), Export(PropertyHint.Range, "0,1000")]
    public int QuantizeSize
    {
        get => _quantizeSize;
        set
        {
            _quantizeSize = value;
            _shader.SetShaderParameter(QuantizeSizeUniform, value);
        }
    }
    [Export(PropertyHint.Range, "1,16,1")]
    public int Levels
    {
        get => _levels;
        set
        {
            _levels = value;
            _shader.SetShaderParameter(LevelsUniform, value);
        }
    }
    [Export(PropertyHint.Range, "1,3,1")]
    public int Pattern
    {
        get => _pattern;
        set
        {
            _pattern = value;
            _shader.SetShaderParameter(DitherPatternUniform, value);
        }
    }
    [Export]
    public bool Dither
    {
        get => _dither;
        set
        {
            _dither = value;
            _shader.SetShaderParameter(DitherEnabledUniform, value);
        }
    }

    private const int MeshSize = 50;
    private Dictionary<LightSource, int> _sourceToIndex = [];
    private MultiMesh _multiMesh;
    private QuadMesh _quadMesh;
    private readonly ShaderMaterial _shader;
    private Texture2D? _texture;
    private int _quantizeSize = 1;
    private bool _dither = false;
    private int _levels = 1;
    private int _pattern = 1;

    /// <summary>
    /// Resets all lookups and light sources
    /// </summary>
    private void Reset(GCol.Array<LightSource?> newSources)
    {
        GD.Print("Resetting.");
        Multimesh = _multiMesh;
        Texture ??= GetDefaultTexture();
        Material = _shader;

        foreach (var kvp in _sourceToIndex)
            UnsubscribeLightEvents(kvp.Key);

        _sourceToIndex.Clear();
        _multiMesh.InstanceCount = newSources.Count;

        for (int i = 0; i < newSources.Count; i++)
        {
            if (newSources[i] is not LightSource lightSource)
                continue;

            _sourceToIndex.Add(lightSource, i);
            _multiMesh.SetInstanceTransform2D(i, GetLightTransform(lightSource));
            _multiMesh.SetInstanceCustomData(i, GetLightCustomData(lightSource));
            SubscribeLightEvents(lightSource);
        }
    }

    /// <summary>
    /// Adds a light source
    /// </summary>
    /// <param name="lightSource"></param>
    private void AddLightSource(LightSource lightSource, bool sub = true)
    {
        if (_sourceToIndex.ContainsKey(lightSource))
            return;

        int index = _multiMesh.InstanceCount;
        _multiMesh.InstanceCount++;
        Sources.Add(lightSource);
        _sourceToIndex.Add(lightSource, index);
        _multiMesh.SetInstanceTransform2D(index, GetLightTransform(lightSource));
        _multiMesh.SetInstanceCustomData(index, GetLightCustomData(lightSource));

        if (sub)
            SubscribeLightEvents(lightSource);
    }

    private void RemoveLightSource(LightSource lightSource, bool unsub = true)
    {
        if (!_sourceToIndex.TryGetValue(lightSource, out int index))
            return;

        // Move last source to now open spot
        if (index != Sources.Count - 1)
        {
            LightSource lastSource = Sources[^1];
            Sources[index] = lastSource;
            _sourceToIndex[lastSource] = index;
            _multiMesh.SetInstanceTransform2D(index, GetLightTransform(lastSource));
            _multiMesh.SetInstanceCustomData(index, GetLightCustomData(lastSource));
        }

        Sources.RemoveAt(Sources.Count - 1);
        _sourceToIndex.Remove(lightSource);
        _multiMesh.InstanceCount--;

        if (unsub)
            UnsubscribeLightEvents(lightSource);
    }

    /// <summary>
    /// Gets a default Gradient texture.
    /// </summary>
    /// <returns></returns>
    private static GradientTexture2D GetDefaultTexture()
    {
        return new()
        {
            Width = MeshSize,
            Height = MeshSize,
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

    /// <summary>
    /// Gets a new Transform2D from the light source's global position.
    /// </summary>
    /// <param name="lightSource"></param>
    /// <returns></returns>
    private static Transform2D GetLightTransform(LightSource lightSource)
    {
        return new(0f, Vector2.One, 0f, lightSource.GlobalPosition.Round());
    }

    /// <summary>
    /// Gets custom data for the light source shader
    /// </summary>
    /// <param name="lightSource"></param>
    /// <returns></returns>
    private Color GetLightCustomData(LightSource lightSource)
    {
        float max = lightSource.MaxSize / Math.Max(_quadMesh.Size.X, _quadMesh.Size.Y);
        return new Color(lightSource.Speed, max, 0, 0);
    }

    private void OnLightSourceGlobalPositionChanged(LightSource lightSource)
    {
        UpdateLightPosition(lightSource);
    }

    private void OnLightSourceVisibilityUpdated(LightSource lightSource)
    {
        if (!_sourceToIndex.TryGetValue(lightSource, out int index))
            return;

        if (lightSource.IsVisibleInTree())
            UpdateLightPosition(lightSource, index);
        else
            _multiMesh.SetInstanceTransform2D(index, new());
    }

    private void OnLightSourceParented(LightSource lightSource)
    {
        AddLightSource(lightSource, false);
    }

    private void OnLightSourceUnparented(LightSource lightSource)
    {
        RemoveLightSource(lightSource, false);
    }

    private void SubscribeLightEvents(LightSource lightSource)
    {
        lightSource.Parented += OnLightSourceParented;
        lightSource.GlobalPositionChanged += OnLightSourceGlobalPositionChanged;
        lightSource.Unparented += OnLightSourceUnparented;
        lightSource.VisibilityUpdated += OnLightSourceVisibilityUpdated;
    }

    private void UnsubscribeLightEvents(LightSource lightSource)
    {
        lightSource.Parented -= OnLightSourceParented;
        lightSource.GlobalPositionChanged -= OnLightSourceGlobalPositionChanged;
        lightSource.Unparented -= OnLightSourceUnparented;
        lightSource.VisibilityUpdated -= OnLightSourceVisibilityUpdated;
    }

    private void UpdateLightPosition(LightSource lightSource)
    {
        if (!_sourceToIndex.TryGetValue(lightSource, out int index))
            return;

        UpdateLightPosition(lightSource, index);
    }

    private void UpdateLightPosition(LightSource lightSource, int index)
    {
        _multiMesh.SetInstanceTransform2D(index, GetLightTransform(lightSource));
        _multiMesh.SetInstanceCustomData(index, GetLightCustomData(lightSource));
    }
}
