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
        _shader ??= new ShaderMaterial() { Shader = GD.Load<Shader>("res://shaders/DitherMesh.gdshader") };
        _shader.SetShaderParameter("handle_scale", true);
        _quadMesh = new() { Size = new(MeshSize, -MeshSize) };
        _multiMesh = new() { Mesh = _quadMesh, UseCustomData = true };
        QuantizeSize = _quantizeSize;
        Dither = _dither;
        Divisions = _divisions;
        Pattern = _pattern;
        Texture ??= GetDefaultTexture();
    }

    public LightMesh(ShaderMaterial shader) : this()
    {
        _shader = shader;
    }

    [ExportGroup("Sources"), Export]
    public GCol.Array<LightSource?> Sources
    {
        get => _sources;
        set
        {
            if (value.Count != value.Distinct().Count())
                return;

            _sources = value;
            Reset();
        }
    }
    [ExportGroup("Dither"), Export(PropertyHint.Range, "0,1000")]
    public int QuantizeSize
    {
        get => _quantizeSize;
        set
        {
            _quantizeSize = value;
            _shader.SetShaderParameter("quantize_size", value);
        }
    }
    [Export(PropertyHint.Range, "1,16,1")]
    public int Divisions
    {
        get => _divisions;
        set
        {
            _divisions = value;
            _shader.SetShaderParameter("divisions", value);
        }
    }
    [Export(PropertyHint.Range, "1,3,1")]
    public int Pattern
    {
        get => _pattern;
        set
        {
            _pattern = value;
            _shader.SetShaderParameter("bayer_pattern", value);
        }
    }
    [Export]
    public bool Dither
    {
        get => _dither;
        set
        {
            _dither = value;
            _shader.SetShaderParameter("dither_enabled", value);
        }
    }

    private const int MeshSize = 50;
    private readonly HashSet<int> _availableIndices = [];
    private readonly Dictionary<LightSource, int> _indexLookup = [];
    private GCol.Array<LightSource?> _sources = [];
    private MultiMesh _multiMesh;
    private QuadMesh _quadMesh;
    private readonly ShaderMaterial _shader;
    private Texture2D? _texture;
    private int _quantizeSize = 1;
    private bool _dither = false;
    private int _divisions = 1;
    private int _pattern = 1;

    /// <summary>
    /// Resets all lookups and light sources
    /// </summary>
    private void Reset()
    {
        Multimesh = _multiMesh;
        Texture ??= GetDefaultTexture();
        Material = _shader;

        foreach (KeyValuePair<LightSource, int> kvp in _indexLookup)
            UnsubscribeLightEvents(kvp.Key);

        _availableIndices.Clear();
        _indexLookup.Clear();

        LightSource[] sources = _sources.OfType<LightSource>().ToArray();
        int oldCount = Math.Max(_multiMesh.InstanceCount, sources.Length);
        _multiMesh.InstanceCount = 0;
        AddInstances(oldCount);

        foreach (LightSource source in sources)
        {
            SubscribeLightEvents(source);
            AddLightSource(source);
        }

        // Fill out the remaining blank instances
        for (int i = sources.Length; i < _multiMesh.InstanceCount; i++)
        {
            int index = GetFreeIndex();
            _availableIndices.Remove(index);
            _multiMesh.SetInstanceTransform2D(index, new());
        }
    }

    /// <summary>
    /// Adds instances to the available indicies.
    /// </summary>
    /// <param name="toAdd"></param>
    private void AddInstances(int toAdd)
    {
        if (toAdd == 0)
            return;

        int oldCount = _multiMesh.InstanceCount;
        int newCount = oldCount + toAdd;
        _multiMesh.InstanceCount = newCount;

        for (int i = oldCount; i < toAdd; i++)
            _availableIndices.Add(i);
    }

    /// <summary>
    /// Adds a light source
    /// </summary>
    /// <param name="lightSource"></param>
    private void AddLightSource(LightSource lightSource)
    {
        if (_indexLookup.ContainsKey(lightSource))
            return;

        int index = GetFreeIndex();
        _availableIndices.Remove(index);
        _indexLookup.Add(lightSource, index);
        _multiMesh.SetInstanceTransform2D(index, GetLightTransform(lightSource));
        _multiMesh.SetInstanceCustomData(index, GetLightCustomData(lightSource));
    }

    /// <summary>
    /// Gets a free index from the available indices and adds instances if none exist.
    /// </summary>
    /// <returns></returns>
    private int GetFreeIndex()
    {
        if (_availableIndices.Count == 0)
            AddInstances(_multiMesh.InstanceCount);

        return _availableIndices.First();
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
        if (!_indexLookup.TryGetValue(lightSource, out int index))
            return;

        if (lightSource.IsVisibleInTree())
            UpdateLightPosition(lightSource, index);
        else
            _multiMesh.SetInstanceTransform2D(index, new());
    }

    private void OnLightSourceParented(LightSource lightSource)
    {
        AddLightSource(lightSource);
        _sources.Add(lightSource);
    }

    private void OnLightSourceUnparented(LightSource lightSource)
    {
        RemoveLightSource(lightSource);
    }

    private void OnLightSourceDeleted(LightSource lightSource)
    {
        UnsubscribeLightEvents(lightSource);
    }

    private void RemoveLightSource(LightSource lightSource)
    {
        if (!_indexLookup.TryGetValue(lightSource, out int index))
            return;

        _sources.Remove(lightSource);
        _indexLookup.Remove(lightSource);
        _availableIndices.Add(index);
        _multiMesh.SetInstanceTransform2D(index, new());
    }

    private void SubscribeLightEvents(LightSource lightSource)
    {
        lightSource.Parented += OnLightSourceParented;
        lightSource.GlobalPositionChanged += OnLightSourceGlobalPositionChanged;
        lightSource.Unparented += OnLightSourceUnparented;
        lightSource.Deleted += OnLightSourceDeleted;
        lightSource.VisibilityUpdated += OnLightSourceVisibilityUpdated;
    }

    private void UnsubscribeLightEvents(LightSource lightSource)
    {
        lightSource.Parented -= OnLightSourceParented;
        lightSource.GlobalPositionChanged -= OnLightSourceGlobalPositionChanged;
        lightSource.Unparented -= OnLightSourceUnparented;
        lightSource.Deleted -= OnLightSourceDeleted;
        lightSource.VisibilityUpdated -= OnLightSourceVisibilityUpdated;
    }

    private void UpdateLightPosition(LightSource lightSource)
    {
        if (!_indexLookup.TryGetValue(lightSource, out int index))
            return;

        UpdateLightPosition(lightSource, index);
    }

    private void UpdateLightPosition(LightSource lightSource, int index)
    {
        _multiMesh.SetInstanceTransform2D(index, GetLightTransform(lightSource));
        _multiMesh.SetInstanceCustomData(index, GetLightCustomData(lightSource));
    }
}
