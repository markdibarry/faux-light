shader_type canvas_item;

varying vec2 world_vertex;

void vertex() {
    // (0,0) is texture origin, in grid pixel size
    // sometimes (0.5,0.5)
    vec2 texture_vertex = VERTEX;

    // (0,0) is grid origin, in grid pixel size
    world_vertex = (MODEL_MATRIX * vec4(texture_vertex, 0, 1)).xy;
    //Includes scale, skew, and rotation
    vec2 transform_scale = (MODEL_MATRIX * vec4(1, 1, 0, 0)).xy;
    vec2 node_global_position = MODEL_MATRIX[3].xy;

    // (0,0) is screen origin, in screen pixel size
    vec2 screen_vertex = (CANVAS_MATRIX * vec4(world_vertex, 0, 1)).xy;
    vec2 zoom_level = (CANVAS_MATRIX * vec4(1, 1, 0, 0)).xy;
    vec2 screen_offset_base = CANVAS_MATRIX[3].xy;
    vec2 screen_offset = screen_offset_base / zoom_level;

    // (0,0) is screen center, values are normalized from (-1,-1) to (1, 1)
    // from top left to bottom right
    vec2 clip_vertex = (SCREEN_MATRIX * vec4(screen_vertex, 0, 1)).xy;
    vec2 screen_size_base = 1. / ((SCREEN_MATRIX * vec4(1, 1, 0, 0)).xy * 0.5);
    vec2 screen_size = screen_size_base / zoom_level;
    vec2 q_screen_vertex = world_vertex + screen_offset;
    vec2 screen_pixel_size = 1. / screen_size;
}