package tt_example

import "core:fmt"
import "core:math"

import rl "vendor:raylib"

import tt "../"
import vm "../../game/vecmath"

main :: proc()
{
  // - Create a transform tree with 100 slots ---
  tree: tt.Tree(f32) = tt.create_tree(f32, 100, context.allocator)
  defer tt.destroy_tree(&tree)

  // - Set the global tree ---
  tt.global_tree = &tree

  // - Create a new transform and set its local values ---
  xform_a: tt.Transform(f32) = tt.alloc_transform(&tree)
  tt.local(xform_a).scl = {1, 1}
  tt.local(xform_a).pos = {100, 100}
  tt.local(xform_a).rot = math.PI

  // - Alternative way to get the transform's local position ---
  fmt.println("A's local position:", tt.local_pos(xform_a))

  // - Alternative way to set the transform's local position ---
  tt.set_local_pos(xform_a, [2]f32{100, 100})

  // - Create a second transform and make it a child of xform_a ---
  xform_b: tt.Transform(f32) = tt.alloc_transform(&tree, xform_a)
  tt.local(xform_b).scl = {1, 1}
  tt.local(xform_b).pos = {10, 10}

  // - Set the transform's global scale ---
  tt.set_global_scl(xform_b, [2]f32{0.5, 3})

  // - Get the transform's global values ---
  fmt.println()
  fmt.println("B's position:", tt.global_pos(xform_b))
  fmt.println("B's scale:", tt.global_scl(xform_b))
  fmt.println("B's rotation:", tt.global_rot(xform_b))

  raylib()
}

WINDOW_WIDTH  :: 900
WINDOW_HEIGHT :: 540

raylib :: proc()
{
  tree: tt.Tree(f32) = tt.create_tree(f32, 100, context.allocator)
  defer tt.destroy_tree(&tree)
  tt.global_tree = &tree

  sun: tt.Transform(f32) = tt.alloc_transform(&tree)
  tt.local(sun).scl = {1, 1}
  tt.local(sun).pos = {0, WINDOW_HEIGHT/2}

  earth: tt.Transform(f32) = tt.alloc_transform(&tree, sun)
  tt.local(earth).scl = {0.25, 0.25}
  tt.local(earth).pos = {100, 100}

  moon: tt.Transform(f32) = tt.alloc_transform(&tree, earth)
  tt.local(moon).scl = {0.5, 0.5}
  tt.local(moon).pos = {100, 100}

  rl.SetTraceLogLevel(.ERROR)
  rl.SetTargetFPS(60)
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TransformTree")

  for !rl.WindowShouldClose()
  {
    // - Update ---
    sun_pos := tt.local(sun).pos
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

    draw_circle(tt.global_pos(sun), tt.global_scl(sun), tt.global_rot(sun), rl.YELLOW)
    draw_circle(tt.global_pos(earth), tt.global_scl(earth), tt.global_rot(earth), rl.BLUE)
    draw_circle(tt.global_pos(moon), tt.global_scl(moon), tt.global_rot(moon), rl.WHITE)

    rl.EndDrawing()
  }

  rl.CloseWindow()
}

draw_circle :: proc(pos, dim: [2]f32, rot: f32, color: rl.Color)
{
  rl.DrawCircleV(pos, dim.x * 50, color)
}
