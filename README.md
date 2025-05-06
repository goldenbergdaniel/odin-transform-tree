# Transform Tree
A simple 2D transform component tree for Odin.

```odin
package tt_example

import "core:fmt"
import "core:math"

import tt "../"

main :: proc()
{
  // - Create a transform tree with 100 slots ---
  tree: tt.Tree(f32) = tt.create_tree(f32, 100, context.allocator)
  defer tt.destroy_tree(&tree)

  // - Set the global tree ---
  tt.set_global_tree(&tree)

  // - Create a new transform and set its local values ---
  xform_a: tt.Transform(f32) = tt.alloc_transform(&tree)
  tt.get(xform_a).scl = {1, 1}
  tt.get(xform_a).pos = {100, 100}
  tt.get(xform_a).rot = math.PI

  // - Get the transform's local position ---
  fmt.println("Local position: ", tt.local_pos(xform_a))

  // - Create a second transform ---
  xform_b: tt.Transform(f32) = tt.alloc_transform(&tree, xform_a)
  tt.get(xform_b).scl = {1, 1}
  tt.get(xform_b).pos = {10, 10}

  // - Set the transform's global scale ---
  tt.set_global_scl(xform_b, [2]f32{0.5, 3})

  // - Get the transform's global values ---
  fmt.println("Position:", tt.global_pos(xform_b))
  fmt.println("   Scale:", tt.global_scl(xform_b))
  fmt.println("Rotation:", tt.global_rot(xform_b))
}
```
