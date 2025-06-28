# Fake 2D Light Mask Example Project

A minimal Godot demo project showcasing 2D light masking node with optional dithering/palette effects like in old pixel games. Drop in any gradient or pattern texture, tweak the size, transparency, dither style, and you’re good to go. No heavyweight `Light2D` nodes, just fast, flexible, pixel-perfect lighting.

## Setup

1. The project contains a `FauxLight` node you add as a child of anything you want to have a light follow. Make sure to set its z-index to a number higher than the thing you want to mask.
2. Add a foreground texture, foreground `Parallax2D`, or add a `Parallax2D` node with a dark overlay and set its `scroll_scale` to `(0,0)`. This makes it effectively behave like a `CanvasLayer` but without breaking rendering order.
3. Place a `BackBufferCopy` node before the overlay with the copy mode set to "Viewport" (so it grabs everything on screen under it).

## Performance

By default, just to keep things snappy, all nodes share the same static shader material, but uses per-instance uniforms for speed, and you can just scale the sprites for different sizes. Feel free to set the shader material to be unique if you want a different pixel size or dithering pattern per light.

## Extra shaders

This also contains demos of some of my other shaders. Read more here: https://godotshaders.com/shader/arbitrary-color-reduction-ordered-dithering/