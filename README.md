# Transform Tree
A simple 2D transform component tree for Odin.

```odin
package main

import "core:fmt"
import "core:math"

import tt "transform_tree"

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
}
```
