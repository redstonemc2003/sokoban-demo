package gal

lerp :: proc(start, end, t : f32) -> f32 {
    return start + (end - start) * t
}