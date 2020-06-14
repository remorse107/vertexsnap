#*************************************************************************/
#*  magnet.gd                                                            */
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
extends ImmediateGeometry
class_name Magnet, "magnet.png"

var magMaterial = preload("res://addons/vertexsnap/magnet.material")

#Reserved
#export(NodePath) var AffectNode 

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		material_override = magMaterial
	else:
		set_process(false)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	clear()

	begin(Mesh.PRIMITIVE_TRIANGLES, null)
	add_sphere(15,15,.05, false)
	end()
	pass
	

 
