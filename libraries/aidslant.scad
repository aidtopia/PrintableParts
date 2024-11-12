// A module to orient its children for diagonal printing.
// I worked this out with Rex 2024-11-09 while helping him with
// his aluminum extrusion connectors inspired by a video on the
// Slant3D YouTube channel: https://youtu.be/csUGcIPNNkk

module slant3d() {
    rotate([atan(sqrt(2)), 0, 0])
        rotate([0, 0, 45])
            children();
}

// demo:

size = 2;
module dot() { sphere(d=size/10, $fn=12); }

module box() {
    cube(size);
    color("white") dot();
    color("red") translate([size, size, size]) dot();
}

slant3d() { box(); }

// The distance between opposing corners of the box:
dist = sqrt(3*size*size);

xoffset = -(size + 0.25);

// After slant3d, the highest corner of the box is at z=dist.
translate([xoffset, 0, dist]) color("green") dot();

// The z-heights of the other corners alternate between
// 1/3*dist and 2/3*dist.
translate([xoffset, 0, 1/3*dist]) color("yellow") dot();
translate([xoffset, 0, 2/3*dist]) color("yellow") dot();
