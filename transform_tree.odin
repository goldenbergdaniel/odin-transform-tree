package transform_tree

import "core:math"

// The float type to use. Default is `f32`
float :: f32

Transform :: struct
{
  id: u32,
}

Transform_Data :: struct
{
  using _:     struct #raw_union
  {
    position:  [2]float,
    pos:       [2]float,
  },
  using _:     struct  #raw_union
  {
    scale:     [2]float,
    scl:       [2]float,
  },
  using _:     struct #raw_union
  {
    rotation:  float,
    rot:       float,
  },
  _prev_free:  ^Transform_Data,
  _ref:        Transform,
  _parent_ref: Transform,
}

Tree :: struct
{
  data:       [dynamic]Transform_Data,
  last_free: ^Transform_Data,
}

@(thread_local)
global_tree: ^Tree

@(require_results)
create_tree :: proc(n: int, allocator := context.allocator) -> Tree 
{
  result: Tree
  result.data = make([dynamic]Transform_Data, 1, n+1, allocator)
  return result
}

clear_tree :: proc(tree: ^Tree)
{
  for &xform in tree.data
  {
    xform = {}
  }
  
  clear(&tree.data)
  append(&tree.data, Transform_Data{})

  tree.last_free = nil
}

destroy_tree :: proc(tree: ^Tree)
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
alloc_transform_parent :: proc(tree: ^Tree, parent: Transform) -> Transform
{
  result: Transform

  if tree.last_free != nil
  {
    result = tree.last_free._ref
    tree.data[result.id]._ref = result
    tree.data[result.id]._parent_ref = parent
    tree.data[result.id].scale = {1, 1}
    tree.last_free = tree.last_free._prev_free
  }
  else
  {
    append(&tree.data, Transform_Data{})
    idx := len(tree.data) - 1
    result = Transform{u32(idx)}
    tree.data[idx]._ref = result
    tree.data[idx]._parent_ref = parent
    tree.data[idx].scale = {1, 1}
  }

  return result
}

@(require_results)
alloc_transform_no_parent :: #force_inline proc(tree: ^Tree) -> Transform
{
  return alloc_transform_parent(tree, Transform{})
}

free_transform :: proc(tree: ^Tree, xform: Transform)
{
  tree.data[xform.id]._prev_free = tree.last_free
  tree.last_free = &tree.data[xform.id]
  
  tree.data[xform.id] = {
    _ref = tree.data[xform.id]._ref,
    _prev_free = tree.data[xform.id]._prev_free,
  }
}

set_parent :: #force_inline proc(child, parent: Transform, tree := global_tree)
{
  if tree == nil do return
  tree.data[child.id]._parent_ref = parent
}

attach_child :: #force_inline proc(parent, child: Transform, tree := global_tree)
{
  set_parent(child, parent, tree)
}

/*
  Returns a pointer to the transform data. The fields `pos`, `scl`, and `rot` give the
  local values and are safe to mutate.
*/
@(require_results)
local :: proc(xform: Transform, tree := global_tree) -> ^Transform_Data
{
  if tree == nil do return {}
  return &tree.data[xform.id]
}

local_pos :: local_position
local_scl :: local_scale
local_rot :: local_rotation

@(require_results)
local_position :: proc(xform: Transform, tree := global_tree) -> [2]float
{
  if tree == nil do return {0, 0}
  return tree.data[xform.id].pos
}

@(require_results)
local_scale :: proc(xform: Transform, tree := global_tree) -> [2]float
{
  if tree == nil do return {0, 0}
  return tree.data[xform.id].scl
}

@(require_results)
local_rotation :: proc(xform: Transform, tree := global_tree) -> float
{
  if tree == nil do return 0
  return tree.data[xform.id].rot
}

set_local_pos :: set_local_position
set_local_scl :: set_local_scale
set_local_rot :: set_local_rotation

set_local_position :: proc(xform: Transform, pos: [2]f32, tree := global_tree)
{
  if tree == nil do return
  tree.data[xform.id].pos = pos
}

set_local_scale :: proc(xform: Transform, scl: [2]f32, tree := global_tree)
{
  if tree == nil do return
  tree.data[xform.id].scl = scl
}

set_local_rotation :: proc(xform: Transform, rot: f32, tree := global_tree)
{
  if tree == nil do return
  tree.data[xform.id].rot = rot
}

global_pos :: global_position
global_scl :: global_scale
global_rot :: global_rotation

@(require_results)
global_position :: proc(xform: Transform, tree := global_tree) -> [2]float
{
  if tree == nil do return {0, 0}

  result: matrix[3,3]float = ident_3x3f(float(1))

  curr_xform := local(xform, tree)
  for curr_xform._ref != {}
  {
    result = model_matrix(curr_xform._ref, tree) * result
    curr_xform = local(curr_xform._parent_ref)
  }

  return {result[0,2], result[1,2]}
}

@(require_results)
global_scale :: proc(xform: Transform, tree := global_tree) -> [2]float
{
  if tree == nil do return {0, 0}

  result: [2]float = {1, 1}
  
  curr_xform := local(xform, tree)
  for curr_xform._ref != {}
  {
    result *= curr_xform.scl
    curr_xform = local(curr_xform._parent_ref)
  }

  return result
}

@(require_results)
global_rotation :: proc(xform: Transform, tree := global_tree) -> float
{
  if tree == nil do return 0
  
  result: float
  
  curr_xform := local(xform, tree)
  for curr_xform._ref != {}
  {
    result += curr_xform.rot
    curr_xform = local(curr_xform._parent_ref)
  }

  return result
}

set_global_pos :: set_global_position
set_global_scl :: set_global_scale
set_global_rot :: set_global_rotation

set_global_position :: proc(xform: Transform, pos: [2]float, tree := global_tree)
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

set_global_scale :: proc(xform: Transform, scl: [2]float, tree := global_tree)
{
  curr_global_scl := global_scl(xform, tree)
  curr_local_scl := local(xform, tree).scl

  local(xform, tree).scl.x *= curr_local_scl.x / curr_global_scl.x * scl.x
  local(xform, tree).scl.y *= curr_local_scl.y / curr_global_scl.y * scl.y
}

set_global_rotation :: proc(xform: Transform, rot: float, tree := global_tree)
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
model_matrix :: proc(xform: Transform, tree := global_tree) -> matrix[3,3]float
{
  if tree == nil do return {}

  xform := tree.data[xform.id]
  result := scale_3x3f(xform.scl)
  result = rotation_3x3f(xform.rot) * result
  result = translation_3x3f(xform.pos) * result
  return result
}

// 2D Matrix ///////////////////////////////////////////////////////////////////////////

@(require_results, private)
ident_3x3f :: #force_inline proc(val: float) -> matrix[3,3]float
{
  return {
    val, 0, 0,
    0, val, 0,
    0, 0, val,
  }
}

@(require_results, private)
translation_3x3f :: proc(v: [2]float) -> matrix[3,3]float
{
  result: matrix[3,3]float = ident_3x3f(float(1))
  result[0,2] = v.x
  result[1,2] = v.y
  return result
}

@(require_results, private)
scale_3x3f :: proc(v: [2]$float) -> matrix[3,3]float
{
  result: matrix[3,3]float = ident_3x3f(float(1))
  result[0,0] = v.x
  result[1,1] = v.y
  return result
}

@(require_results, private)
shear_3x3f :: proc(v: [2]float) -> matrix[3,3]float
{
  result: matrix[3,3]float = ident_3x3f(float(1))
  result[0,1] = v.x
  result[1,0] = v.y
  return result
}

@(require_results, private)
rotation_3x3f :: proc(rads: float) -> matrix[3,3]float
{
  result: matrix[3,3]float = ident_3x3f(float(1))
  result[0,0] = math.cos(rads)
  result[0,1] = -math.sin(rads)
  result[1,0] = math.sin(rads)
  result[1,1] = math.cos(rads)
  return result
}
