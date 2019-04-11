# ProjectSnow
Project snow is my personal Unity project where I wanted to try making my own shader and snow looked like a good example.

This shader is far from optimal and uses quite a lot of dynamic branching which might impact performance.

It is based on Physically based (Standard) Unity shaders. It includes 3 parts at this moment
* Standard shader for objects
* Standard shader with distance based tessellation (Snow fills holes in object)
* Standard shader for terrain (currently supports only 1 splatmap = 4 textures)

All shaders work with world vectors, so there will be no snow on polygons that are upside down in the world. All shaders also blend at these angles based on height, not just angle.
