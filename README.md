# VertexSnap v0.1
### This is a Godot 3.2 plugin that assists in 3D Level Design.
It's current features are:
* Match Object's:
    * Rotation
    * Scale
    * X, Y and Z positions independently
* Snap object's together by a vertex

### How to Use

Plugin only operates on selected object.  Reason is to not traverse entire scene tree if it can be avoided.

#### Select the source object to match with

Hover Near Mesh Instance Vertex + RMB + Shift

#### Transform Object to Source Object

Hover Near Mesh Instance Vertex + RMB + Control

#### Highly Detailed Meshes

In some cases it might be difficult to lock in a the correct vertex.  For these cases you might want to provide a helper node to provide a visual cue to where the vertex you want is located.  To add this visual cue to your mesh simply:

Hover Near Mesh Instance Vertex + MMB + Shift

### The Dock Window

The dock window for this tool provides options for how you wish to transform your object in relation to the source object.  This window will allow you to match scale, rotation or even X,Y,Z coordinates independently.  So, you can easily align objects in line if you wish.

Finally, the last option is to snap the vertexes together.  Source object never transforms, only the object where you apply the Ctrl + RMB interaction will transform.

Make sure that you have selected how you wish to transform your object first by adjusting the dock window settings.


### Known Issues

* Scaling normalization is not performed on collider shapes.  My recommendation is to make sure that all your subscenes that you wish to snap together are already correctly scaled.  Use scaling at your own risk.
* Not yet tested with deep sub scene hieracrchies.  Transforms are performed at the node owner levels.
* Only works with MeshInstances (or MeshInstances found in sub scenes).
* Currently no undo system in place.
* No visual highlighting of the source object selected vertex.