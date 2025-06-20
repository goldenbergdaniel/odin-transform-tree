package tt_example_basic

import "core:fmt"
import "core:math"

import tt "../../"

main :: proc()
{
  // - Create a transform tree with 100 reserved slots ---
  tree: tt.Transform_Tree = tt.create_tree(100, context.allocator)
  defer tt.destroy_tree(&tree)

  // - Set the global tree ---
  tt.global_tree = &tree

  // - Create a new transform and set its local values ---
  xform_a: tt.Transform = tt.alloc_transform(&tree)
  tt.local(xform_a).position = {100, 100}
  tt.local(xform_a).scale = {1, 1}
  tt.local(xform_a).rotation = math.PI

  // - Alternative way to get the transform's local position ---
  _ = tt.local_position(xform_a)

  // - Alternative way to set the transform's local position ---
  tt.set_local_position(xform_a, [2]f32{100, 100})

  // - Can also use shorthands (pos, scl, rot) ---
  _ = tt.local(xform_a).pos
  tt.set_local_pos(xform_a, [2]f32{100, 100})

  // - Create a second transform and make it a child of xform_a ---
  xform_b: tt.Transform = tt.alloc_transform(&tree, xform_a)
  tt.local(xform_b).scl = {1, 1}
  tt.local(xform_b).pos = {10, 10}

  // - Set the transform's global scale ---
  tt.set_global_scale(xform_b, [2]f32{0.5, 3})

  // - Get the transform's global values ---
  fmt.println("B's global position:", tt.global_position(xform_b))
  fmt.println("B's global scale:", tt.global_scale(xform_b))
  fmt.println("B's global rotation:", tt.global_rotation(xform_b))

  // - Free the transforms ---
  tt.free_transform(&tree, xform_a)
  tt.free_transform(&tree, xform_b)
}
