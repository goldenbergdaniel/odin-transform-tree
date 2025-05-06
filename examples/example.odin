package transforms

import "core:fmt"
import "core:math"

import tt "transform_tree"

main :: proc()
{
  tree := tt.create_tree(f32, 100, context.allocator)
  defer tt.destroy_tree(&tree)
  tt.set_global_tree(&tree)

  xform_a := tt.alloc_transform(&tree, tt.Transform(f32){})
  tt.get(xform_a).scl = {1, 1}
  tt.get(xform_a).pos = {100, 100}
  tt.get(xform_a).pos *= 2
  tt.get(xform_a).rot = 30

  tt.local_pos(xform_a)

  xform_b := tt.alloc_transform(&tree, xform_a)
  tt.get(xform_b).scl = {1, 1}
  tt.get(xform_b).pos = {10, 10}
  tt.set_global_rot(xform_b, 20)
  tt.set_global_scl(xform_b, [2]f32{0.5, 3})
  tt.set_global_pos(xform_b, [2]f32{300, 20})

  fmt.println("Position:", tt.global_pos(xform_b))
  fmt.println("   Scale:", tt.global_scl(xform_b))
  fmt.println("Rotation:", tt.global_rot(xform_b))
}
