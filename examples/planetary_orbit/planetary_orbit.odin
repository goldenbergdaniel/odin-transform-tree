package tt_example_raylib

import "core:fmt"
import "core:math"

import rl "vendor:raylib"
import tt "../../"

WINDOW_WIDTH  :: 900
WINDOW_HEIGHT :: 540

Entity :: struct
{
  xform: tt.Transform(f32),
  color: rl.Color,
}

main :: proc()
{
  tree: tt.Tree(f32) = tt.create_tree(f32, 100, context.allocator)
  defer tt.destroy_tree(&tree)
  tt.global_tree = &tree

  sun: Entity
  sun.color = rl.YELLOW
  sun.xform = tt.alloc_transform(&tree)
  tt.local(sun.xform).scl = {1, 1}
  tt.local(sun.xform).pos = {0, WINDOW_HEIGHT/2}

  earth: Entity
  earth.color = rl.BLUE
  earth.xform = tt.alloc_transform(&tree, sun.xform)
  tt.local(earth.xform).scl = {0.25, 0.25}
  tt.local(earth.xform).pos = {100, 100}

  moon: Entity
  moon.color = rl.WHITE
  moon.xform = tt.alloc_transform(&tree, earth.xform)
  tt.local(moon.xform).scl = {0.5, 0.5}
  tt.local(moon.xform).pos = {100, 100}

  rl.SetTraceLogLevel(.ERROR)
  rl.SetTargetFPS(60)
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TransformTree")

  for !rl.WindowShouldClose()
  {
    // - Update ---
    sun_pos := tt.local(sun.xform).pos
    if sun_pos.x > 1000
    {
      tt.set_global_pos(sun.xform, [2]f32{-50, sun_pos.y})
    }

    tt.local(sun.xform).pos.x += 100 * rl.GetFrameTime()
    tt.local(sun.xform).rot += 1 * rl.GetFrameTime()
    tt.local(earth.xform).rot += 3 * rl.GetFrameTime()

    // - Draw ---
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    draw_circle(tt.global_pos(sun.xform), tt.global_scl(sun.xform), sun.color)
    draw_circle(tt.global_pos(earth.xform), tt.global_scl(earth.xform), earth.color)
    draw_circle(tt.global_pos(moon.xform), tt.global_scl(moon.xform), moon.color)

    rl.EndDrawing()
  }

  rl.CloseWindow()
}

draw_circle :: proc(pos, dim: [2]f32, color: rl.Color)
{
  rl.DrawCircleV(pos, dim.x * 50, color)
}
