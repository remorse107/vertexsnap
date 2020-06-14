#*************************************************************************/
#*  plugin.gd                                                            */
#*************************************************************************/
#*                       This file is part of:                           */
#*                           Vertex Snap                                 */
#*************************************************************************/
#* Copyright (c) 2020 Robert Morse                                       */
#*                                                                       */
#* Permission is hereby granted, free of charge, to any person obtaining */
#* a copy of this software and associated documentation files (the       */
#* "Software"), to deal in the Software without restriction, including   */
#* without limitation the rights to use, copy, modify, merge, publish,   */
#* distribute, sublicense, and/or sell copies of the Software, and to    */
#* permit persons to whom the Software is furnished to do so, subject to */
#* the following conditions:                                             */
#*                                                                       */
#* The above copyright notice and this permission notice shall be        */
#* included in all copies or substantial portions of the Software.       */
#*                                                                       */
#* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
#* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
#* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
#* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
#* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
#* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
#* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
#*************************************************************************/

tool
extends EditorPlugin

var _camera:Camera

var _camera_direction:Vector3
var _camera_end:Vector3			#Track the camera ray
var _camera_start:Vector3

var _dock_control = preload("res://addons/vertexsnap/dock.tscn").instance()

var _edit_item:Spatial = null	#Item being edited
var _face_normal #Leave as variant
var _found_face_normal
var _found_mesh:MeshInstance = null
var _found_point:Vector3
var _found_face_point1:Vector3
var _found_face_point2:Vector3
var _found_face_point3:Vector3
var _mouse_position:Vector2
var _nodes:Array

var _source_item:Spatial = null
var _source_vector:Vector3

func _enter_tree():
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _dock_control)
	pass
	
func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _dock_control)
	pass

func handles(object):
	if object is Spatial:
		return true
	return false

func edit(object):
	_edit_item = object

func forward_spatial_gui_input(camera, event):
	_camera = camera
	if event is InputEventMouse:
		var ev:InputEventMouse = event
		_mouse_position = ev.position
		
		#Compute camera ray into scene
		_camera_start = camera.project_ray_origin(_mouse_position)
		_camera_end = _camera_start + camera.project_ray_normal(_mouse_position) * 1000
		_camera_direction = camera.project_ray_normal(_mouse_position)
		
		if (ev!=null and ev.button_mask == BUTTON_MASK_MIDDLE):
			if (ev.control):
				_collect_nodes()
				_get_closest_face_and_point()
				if _found_mesh!=null:
					#Add magnet
					var mag:Spatial = preload("res://addons/vertexsnap/magnet.gd").new()
					if mag!=null:
						_found_mesh.add_child(mag)
						mag.owner = _found_mesh.get_owner()
						var v:Vector3 = mag.global_transform.xform(Vector3.ZERO)
						var vt:Vector3 = _found_mesh.global_transform.xform(_found_point)
						mag.global_translate(vt-v)
						mag.set_meta("_edit_lock_", true)
				return true
		
		if (ev!=null and ev.button_mask == BUTTON_MASK_RIGHT):
			if (ev.shift):
				_collect_nodes()
				_get_closest_face_and_point()
				if _found_mesh!=null:
					_source_item = _found_mesh
					_source_vector = _found_point
					_found_face_normal = _face_normal
				return true
					
			if (ev.control):
				_collect_nodes()
				_get_closest_face_and_point()
				print(_found_mesh)
				if _found_mesh!=null:
					var si:Spatial = _source_item
					var fi:Spatial = _found_mesh
					var offset:Vector3 = Vector3.ZERO
					var _owner = fi.get_owner()
					
					if _owner == get_editor_interface().get_edited_scene_root():
						print("change owner")
						_owner = fi

					if _dock_control.match_x():
						var fromPoint:Vector3 = fi.global_transform.xform(Vector3.ZERO)
						var toPoint:Vector3 = si.global_transform.xform(Vector3.ZERO)
						var np:Vector3 = (toPoint - fromPoint)
						np.y = 0
						np.z = 0
						_owner.global_translate(np)
					if _dock_control.match_y():
						var fromPoint:Vector3 = fi.global_transform.xform(Vector3.ZERO)
						var toPoint:Vector3 = si.global_transform.xform(Vector3.ZERO)
						var np:Vector3 = (toPoint - fromPoint)
						np.x = 0
						np.z = 0
						_owner.global_translate(np)
					if _dock_control.match_z():
						var fromPoint:Vector3 = fi.global_transform.xform(Vector3.ZERO)
						var toPoint:Vector3 = si.global_transform.xform(Vector3.ZERO)
						var np:Vector3 = (toPoint - fromPoint)
						np.y = 0
						np.x = 0
						_owner.global_translate(np)
					if _dock_control.match_scale():
						var scaleVector:Vector3 = si.global_transform.basis.get_scale()
						var currentScaleVector:Vector3 = fi.global_transform.basis.get_scale()
						_owner.global_scale(scaleVector / currentScaleVector)
					if _dock_control.match_rotation():
						var saveScale:Vector3 = fi.global_transform.basis.get_scale()
						var saveLocation:Vector3 = fi.global_transform.xform(Vector3.ZERO)
						_owner.global_transform = si.get_owner().global_transform
						_owner.global_translate(saveLocation - fi.global_transform.xform(Vector3.ZERO))
						_owner.global_scale(saveScale / fi.global_transform.basis.get_scale())
					if _dock_control.snap_vertex():
						var fromPoint:Vector3 = fi.global_transform.xform(_found_point)
						var toPoint:Vector3 = si.global_transform.xform(_source_vector)
						_owner.global_translate(toPoint - fromPoint)
				return true
	return false



# There is a bug (or it simply doesn't work like I think it should) in Godot's instances_cull_ray	
# method.  It doesn't seem to consider the node's transformed AABB when intersecting with the 
# camera's projected array (to mouse)
func _collect_nodes():
	var _node_stack = []
	
	#Make sure the node stack is clear before adding anything more
	_nodes.clear()
	_node_stack.clear()
	_node_stack.push_back(_edit_item)
	
	#Collect all nodes where mouse ray contains a potential intersection
	while _node_stack.size()>0:
		var _n = _node_stack.pop_back()
		
		if _n is VisualInstance :
			var vi:VisualInstance = _n
			var aabb:AABB = vi.get_transformed_aabb()
			
			if aabb.intersects_segment(_camera_start, _camera_end):
				_nodes.push_back(_n)
		
		if _n is Magnet:
			_nodes.push_back(_n)
		
		for childNode in _n.get_children():
			_node_stack.push_back(childNode)
	pass

func _get_closest_face_and_point():
	var findVertex:bool = _dock_control.snap_vertex()
	var useMagnets:bool = _dock_control.use_magnets()
	
	var current_length = 0.0
	var distance_to_camera:float = 999999.0
	var distance_to_face:float = 999999.0
	
	#By default, assume that a face was not found.
	_face_normal = null
	
	_found_mesh = null
	
	for n in _nodes:
		if !(n is MeshInstance):
			continue
			
		if n is MeshInstance:
			var mi:MeshInstance = n
			var faces:PoolVector3Array = mi.get_mesh().get_faces()
			
			for fi in range(0,faces.size(), 3):
				var p1:Vector3 = mi.global_transform.xform(faces[fi])
				var p2:Vector3 = mi.global_transform.xform(faces[fi+1])
				var p3:Vector3 = mi.global_transform.xform(faces[fi+2])
				
				#Face also needs to not back cull, need a check for that somewhere
				var facePoint = Geometry.ray_intersects_triangle(_camera_start, _camera_direction, p1, p2, p3 )
				if facePoint!=null:
					var length:float = (facePoint - _camera_start).length()
					if length < distance_to_face:
						distance_to_face = length
						_found_face_point1 = p1
						_found_face_point2 = p2
						_found_face_point3 = p3
						_face_normal = (p3-p1).cross(p2-p1).normalized()
							
				if (_camera.unproject_position(p1) - _mouse_position).length() <= 10:
					current_length = (p1 - _camera_start).length()
					if current_length < distance_to_camera:
						distance_to_camera = current_length
						_found_mesh = mi
						_found_point = faces[fi]
						
				if (_camera.unproject_position(p2) - _mouse_position).length() <= 10:
					current_length = (p2 - _camera_start).length()
					if current_length < distance_to_camera:
						distance_to_camera = current_length
						_found_mesh = mi
						_found_point = faces[fi+1]
						
				if (_camera.unproject_position(p3) - _mouse_position).length() <= 10:
					current_length = (p3 - _camera_start).length()
					if current_length < distance_to_camera:
						distance_to_camera = current_length
						_found_mesh = mi
						_found_point = faces[fi+2]

	pass
