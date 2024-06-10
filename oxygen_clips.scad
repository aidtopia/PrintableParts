// Clips to hold oxygen tubing along a ceiling or wall.
// Sized to be attached with small double-sided tape that is
// 1/2" x 5/8" (12.5 mm, 13.7 mm).  3M sells packs of small
// hooks for holiday lights.  Those packs include Command™
// tapes that fit the bill.
//
// material:            PLA
// nozzle diameter:     0.4 mm
// layer height:        0.3 mm
// minimum perimeters:  1  <=== 
// infill:             15%
//
// Adrian McCarthy 2024-06-09

nozzle_d = 0.4;
id = 6.5 + nozzle_d;
th = 2.2;
tape_w = 12.5;
tape_l = 16.5;  // just the sticky part

od = id + 2*th;

r = (id+od)/2/2;
x0 = 0 - r;
x1 = x0 + tape_w;
y0 = 0 - r;
y1 = 0 + r;

profile = [
    [x1, y1+th, th],
    [x0, y1+th, th],
    [x0, 0, th]
];

linear_extrude(tape_l + nozzle_d) {
    hull() {
        translate([x1, y1+th]) circle(d=th, $fs=nozzle_d/2);
        translate([x0, y1+th]) circle(d=th, $fs=nozzle_d/2);
    }
    hull() {
        translate([x0, y1+th]) circle(d=th, $fs=nozzle_d/2);
        translate([x0, 0    ]) circle(d=th, $fs=nozzle_d/2);
    }
    translate([r+th, y1+0.75*th]) circle(d=th, $fs=nozzle_d/2);
    da = 6;
    for (theta=[180+da:6:360]) {
        hull() {
            rotate([0, 0, theta])   translate([r, 0]) circle(d=th, $fs=nozzle_d/2);
            rotate([0, 0, theta-da]) translate([r, 0]) circle(d=th, $fs=nozzle_d/2);
        }
    }
}

if ($preview) {
    #linear_extrude(tape_l) translate([x0, 10]) square([tape_w, 1.1]);
}
