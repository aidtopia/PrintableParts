// Tool Holder
// Adrian McCarthy 2022-12-05

// Holds side cutters, needle nose pliers, and similar tools.


module tool_holder(th=2.4) {
    r = 5;
    h = 55;
    w = 35;
    dx0 = w/2;
    dx1 = 3/7*w/2;
    dy = 15 + th;
    dz = th;
    z0 = r;
    z1 = h - r;
    slots = 3;
    
    module skew(amt=0.15) {
        multmatrix([[1, 0, 0, 0],
                [0, 1, amt, 0],
                [0, 0, 1, 0]]) children();
    }

    module divider() {
        linear_extrude(th) {
            hull() {
                translate([-dx0, z0]) circle(r);
                translate([-dx1, z1]) circle(r);
            }
            hull() {
                translate([-dx1, z1]) circle(r);
                translate([ dx1, z1]) circle(r);
            }
            hull() {
                translate([ dx1, z1]) circle(r);
                translate([ dx0, z0]) circle(r);
            }
            hull() {
                translate([ dx0, z0]) circle(r);
                translate([-dx0, z0]) circle(r);
            }
        }
    }
    
    for (i = [0:slots]) {
        skew()
            translate([0, dy*i, dz*i])
                rotate([90, 0, 0])
                    divider();
        translate([-w/2, dy*i, dz*i])
            cube([w, (slots-i)*dy + th, th]);
    }
    translate([-w/2, slots*dy, 0])
        cube([w, dy, th]);

}

tool_holder();
