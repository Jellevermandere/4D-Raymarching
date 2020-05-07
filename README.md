# 4D-Raymarching
a Unity framework to create spacial 4 dimentional games, using raymarching

## Check out the making of:
https://youtu.be/nUExziADzjc

## Workings
### raymarching
This project uses raymarching, the objects are expanded to the 4th dimension. so each object is defined by 4 parameters: x,y,z,w.

The world then fixes the W axis to a set value nad the resulting shapes can be displayed in 3D space.

### placing objets
objects can be added with a null and a single script that controls the 4 dimensional PSR and type of boolean operator.

### rendering objects
the objects have their individual color settings.
The camera raymarching script controls all other visual aspects like rendering distance, shadows, normals, and worldcolors.

MIT licence
