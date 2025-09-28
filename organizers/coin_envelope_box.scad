// Boxes to hold #1 coin envelopes.
// I use these for storing and organizing small electronic components.
//
// 2022-08-24 Adrian McCarthy

module envelope_box(envelope_w, envelope_h, wall_th=1.2, clearance=1) {
    box_w = wall_th + envelope_w + clearance + wall_th;
    box_h = wall_th + 0.4*envelope_h;
    box_d = 150;  // fits Sterilite 6-quart shoebox
    multmatrix([[1, 0, 0, 0],
                [0, 1, 0.2, 0],
                [0, 0, 1, 0]]) {
        difference() {
            cube([box_w, box_d, box_h]);
            translate([wall_th, wall_th, wall_th])
                cube([envelope_w + clearance, box_d - 2*wall_th, box_h]);
        }
        
        // Little ridges in the floor of the box help envelopes
        // stand upright when the box is less than full.
        dy = 10;
        ridge = 1.25*wall_th;
        translate([wall_th + clearance/2, 0, 0]) {
            for (y = [dy:dy:box_d - dy]) {
                translate([0, y, 0]) rotate([45, 0, 0])
                    cube([envelope_w, ridge, ridge]);
            }
        }
    }
}

module divider(envelope_w, envelope_h, label_h=25.4/2, th=1.2, nozzle_d=0.4) {
    r = 3;
    dx = envelope_w/2 - r;
    dy = envelope_h/2 - r;
    extra = label_h + 2*r;
    $fs = nozzle_d/2;
    difference() {
        linear_extrude(th) {
            difference() {
                hull() {
                    translate([-dx, -dy]) circle(r=r);
                    translate([ dx, -dy]) circle(r=r);
                    translate([-dx,  dy + extra]) circle(r=r);
                    translate([ dx,  dy + extra]) circle(r=r);
                }
                hull() {
                    translate([        0,  dy - 2*r]) circle(r=r);
                    translate([-dx + 2*r,     extra]) circle(r=r);
                    translate([ dx - 2*r,    -extra]) circle(r=r);
                    translate([        0, -dy + 2*r]) circle(r=r);
                }
            }
        }
        translate([-dx, dy+2*r, max(th/2, th-nozzle_d)]) {
            cube([2*dx, label_h, th]);
        }
    }
}

module coin_envelope_box() {
    envelope_box(57, 89, wall_th=1.2, clearance=1);
}

module coin_envelope_divider(nozzle_d=0.4) {
    divider(57, 89, nozzle_d=nozzle_d);
}

coin_envelope_box();
//coin_envelope_divider();
