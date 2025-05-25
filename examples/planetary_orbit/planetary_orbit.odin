package tt_example_orbit

import "core:fmt"
import "core:math"

import rl "vendor:raylib"
import tt "../../"

WINDOW_WIDTH  :: 900
WINDOW_HEIGHT :: 540

Entity :: struct
{
  #subtype xform: tt.Transform,
  color:          rl.Color,
}

main :: proc()
{
  tree: tt.Tree = tt.create_tree(4, context.allocator)
  defer tt.destroy_tree(&tree)
  tt.global_tree = &tree

  sun: Entity
  sun.color = rl.YELLOW
  sun.xform = tt.alloc_transform(&tree)
  tt.local(sun).scl = {1, 1}
  tt.local(sun).pos = {0, WINDOW_HEIGHT/2}

  earth: Entity
  earth.color = rl.BLUE
  earth.xform = tt.alloc_transform(&tree, sun)
  tt.local(earth).scl = {0.25, 0.25}
  tt.local(earth).pos = {100, 100}

  moon: Entity
  moon.color = rl.WHITE
  moon.xform = tt.alloc_transform(&tree, earth)
  tt.local(moon).scl = {0.5, 0.5}
  tt.local(moon).pos = {100, 100}

  rl.SetTraceLogLevel(.ERROR)
  rl.SetTargetFPS(60)
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TransformTree")

  for !rl.WindowShouldClose()
  {
    // - Update ---
    sun_pos := tt.local(sun).position
    if sun_pos.x > 1000
    {
      tt.set_global_pos(sun, [2]f32{-50, sun_pos.y})
    }

    tt.local(sun).pos.x += 100 * rl.GetFrameTime()
    tt.local(sun).rot += 1 * rl.GetFrameTime()
    tt.local(earth).rot += 3 * rl.GetFrameTime()

    // - Draw ---
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    draw_circle(tt.global_pos(sun), tt.global_scl(sun), sun.color)
    draw_circle(tt.global_pos(earth), tt.global_scl(earth), earth.color)
    draw_circle(tt.global_pos(moon), tt.global_scl(moon), moon.color)

    rl.EndDrawing()
  }

  rl.CloseWindow()
}

draw_circle :: proc(pos, dim: [2]f32, color: rl.Color)
{
  rl.DrawCircleV(pos, dim.x * 50, color)
}
