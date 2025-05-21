package transform_tree

import "base:intrinsics"
import "core:math"

Transform :: struct($E: typeid)
{
  id: u32,
}

Transform_Data :: struct($E: typeid)
{
  id:        Transform(E),
  parent_id: Transform(E),
  pos:       [2]E,
  scl:       [2]E,
  rot:       E,
}

Tree :: struct($E: typeid)
{
  data: []Transform_Data(E),
  len:  int,
  cap:  int,
}

Tree_Union :: union
{
  ^Tree(f16),
  ^Tree(f32),
  ^Tree(f64),
}

@(thread_local)
global_tree: Tree_Union

@(require_results)
create_tree :: proc($E: typeid, cap: int, allocator := context.allocator) -> Tree(E) 
  where intrinsics.type_is_float(E)
{
  result: Tree(E)
  result.data = make([]Transform_Data(E), cap, allocator)
  return result
}

destroy_tree :: proc(tree: ^Tree($E))
{
  delete(tree.data)
  tree^ = {}
}

alloc_transform :: proc
{
  alloc_transform_parent, 
  alloc_transform_no_parent, 
}

@(require_results)
alloc_transform_parent :: proc(tree: ^Tree($E), parent: Transform(E)) -> Transform(E)
{
  result: Transform(E)

  for &slot, idx in tree.data
  {
    idx := u32(idx)
    if idx == 0 do continue

    if slot == {}
    {
      slot.id = Transform(E){idx}
      slot.parent_id = parent
      result = slot.id
      break
    }
  }

  tree.len += 1

  return result
}

@(require_results)
alloc_transform_no_parent :: #force_inline proc(tree: ^Tree($E)) -> Transform(E)
{
  return alloc_transform_parent(tree, Transform(E){})
}

free_transform :: proc(tree: ^Tree($E), xform: Transform(E))
{
  tree.data[xform] = {}
}

set_parent :: proc(parent: Transform($E), tree := global_tree)
{
  if tree == nil do return
  tree.(^Tree(E)).data[child.id].parent_id = parent.id
}

/*
Returns a pointer to the transform data. The fields `pos`, `scl`, and `rot` give the
local values and are safe to mutate.
*/
@(require_results)
local :: proc(xform: Transform($E), tree := global_tree) -> ^Transform_Data(E)
{
  if tree == nil do return {}
  return &tree.(^Tree(E)).data[xform.id]
}

@(require_results)
local_pos :: proc(xform: Transform($E), tree := global_tree) -> [2]E
{
  if tree == nil do return {0, 0}
  return tree.(^Tree(E)).data[xform.id].pos
}

@(require_results)
local_scl :: proc(xform: Transform($E), tree := global_tree) -> [2]E
{
  if tree == nil do return {0, 0}
  return tree.(^Tree(E)).data[xform.id].scl
}

@(require_results)
local_rot :: proc(xform: Transform($E), tree := global_tree) -> E
{
  if tree == nil do return 0
  return tree.(^Tree(E)).data[xform.id].rot
}

set_local_pos :: proc(xform: Transform($E), pos: [2]f32, tree := global_tree)
{
  if tree == nil do return
  tree.(^Tree(E)).data[xform.id].pos = pos
}

set_local_scl :: proc(xform: Transform($E), scl: [2]f32, tree := global_tree)
{
  if tree == nil do return
  tree.(^Tree(E)).data[xform.id].scl = scl
}

set_local_rot :: proc(xform: Transform($E), rot: f32, tree := global_tree)
{
  if tree == nil do return
  tree.(^Tree(E)).data[xform.id].rot = rot
}

@(require_results)
global_pos :: proc(xform: Transform($E), tree := global_tree) -> [2]E
{
  if tree == nil do return {0, 0}

  result: matrix[3,3]E = ident_3x3f(E(1))

  curr_xform := local(xform, tree.(^Tree(E)))
  for curr_xform.id != {}
  {
    result = model_matrix(curr_xform.id, tree) * result
    curr_xform = local(curr_xform.parent_id)
  }

  return {result[0,2], result[1,2]}
}

@(require_results)
global_scl :: proc(xform: Transform($E), tree := global_tree) -> [2]E
{
  if tree == nil do return {0, 0}

  result: [2]E = {1, 1}
  
  curr_xform := local(xform, tree.(^Tree(E)))
  for curr_xform.id != {}
  {
    result *= curr_xform.scl
    curr_xform = local(curr_xform.parent_id)
  }

  return result
}

@(require_results)
global_rot :: proc(xform: Transform($E), tree := global_tree) -> E
{
  if tree == nil do return 0
  
  result: E
  
  curr_xform := local(xform, tree.(^Tree(E)))
  for curr_xform.id != {}
  {
    result += curr_xform.rot
    curr_xform = local(curr_xform.parent_id)
  }

  return result
}

set_global_pos :: proc(xform: Transform($E), pos: [2]E, tree := global_tree)
{
  if tree == nil do return

  curr_global_pos := global_pos(xform, tree)

  if curr_global_pos.x < pos.x
  {
    local(xform, tree).pos.x += abs(curr_global_pos.x - pos.x)
  }
  else if curr_global_pos.x > pos.x
  {
    local(xform, tree).pos.x -= abs(curr_global_pos.x - pos.x)
  }

  if curr_global_pos.y < pos.y
  {
    local(xform, tree).pos.y += abs(curr_global_pos.y - pos.y)
  }
  else if curr_global_pos.y > pos.y
  {
    local(xform, tree).pos.y -= abs(curr_global_pos.y - pos.y)
  }
}

set_global_scl :: proc(xform: Transform($E), scl: [2]E, tree := global_tree)
{
  curr_global_scl := global_scl(xform, tree)
  curr_local_scl := local(xform, tree).scl

  local(xform, tree).scl.x *= curr_local_scl.x / curr_global_scl.x * scl.x
  local(xform, tree).scl.y *= curr_local_scl.y / curr_global_scl.y * scl.y
}

set_global_rot :: proc(xform: Transform($E), rot: E, tree := global_tree)
{
  curr_global_rot := global_rot(xform, tree)
  if curr_global_rot < rot
  {
    local(xform, tree).rot += abs(curr_global_rot - rot)
  }
  else if curr_global_rot > rot
  {
    local(xform, tree).rot -= abs(curr_global_rot - rot)
  }
}

@(require_results)
model_matrix :: proc(xform: Transform($E), tree := global_tree) -> matrix[3,3]E
{
  if tree == nil do return {}

  xform := tree.(^Tree(E)).data[xform.id]
  result := ident_3x3f(E(1.0))
  result = scale_3x3f(xform.scl) * result
  result = rotation_3x3f(xform.rot) * result
  result = translation_3x3f(xform.pos) * result
  return result
}

// 2D Matrix ///////////////////////////////////////////////////////////////////////////

@(require_results, private)
ident_3x3f :: #force_inline proc(val: $E) -> matrix[3,3]E
{
  return {
    val, 0, 0,
    0, val, 0,
    0, 0, val,
  }
}

@(require_results, private)
translation_3x3f :: proc(v: [2]$E) -> matrix[3,3]E
{
  result: matrix[3,3]E = ident_3x3f(E(1))
  result[0,2] = v.x
  result[1,2] = v.y
  return result
}

@(require_results, private)
scale_3x3f :: proc(v: [2]$E) -> matrix[3,3]E
{
  result: matrix[3,3]E = ident_3x3f(E(1))
  result[0,0] = v.x
  result[1,1] = v.y
  return result
}

@(require_results, private)
shear_3x3f :: proc(v: [2]$E) -> matrix[3,3]E
{
  result: matrix[3,3]E = ident_3x3f(E(1))
  result[0,1] = v.x
  result[1,0] = v.y
  return result
}

@(require_results, private)
rotation_3x3f :: proc(rads: $E) -> matrix[3,3]E
{
  result: matrix[3,3]E = ident_3x3f(E(1))
  result[0,0] = math.cos(rads)
  result[0,1] = -math.sin(rads)
  result[1,0] = math.sin(rads)
  result[1,1] = math.cos(rads)
  return result
}
