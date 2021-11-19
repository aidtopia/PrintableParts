// Center Finder
// Adrian McCarthy 2021

module center_finder(width=4*25.4, height=0.67*25.4) {
    $fs=0.2;
    r = 25.4/4;
    spacing = width + 2*r;
    offset = spacing/2;
    difference() {
        union() {
            linear_extrude(3) hull() {
                translate([-offset, 0]) circle(r=r);
                translate([ offset, 0]) circle(r=r);
            }
            translate([-offset, 0, 0]) cylinder(r=r, h=height);
            translate([ offset, 0, 0]) cylinder(r=r, h=height);
        }
        translate([0, 0, -0.1]) cylinder(h=3.2, d1=5, d2=3);
    }
}

center_finder();
