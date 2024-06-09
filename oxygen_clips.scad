// Clips to hold oxygen tubing along a ceiling or wall.
// Sized to be attached with small double-sided tape that is
// 1/2" x 5/8" (12.5 mm, 13.7 mm).  3M sells packs of small
// hooks for holiday lights.  Those packs include Command™
// tapes that fit the bill.
//
// Adrian McCarthy 2024-06-09

nozzle_d = 0.4;
id = 6.5 + nozzle_d;
th = 3;

od = id + 2*th;

r = (id+od)/2/2;
x0 = 0 - r;
x1 = 0 + r;
y0 = 0 - r;
y1 = 0 + r;

profile = [
    [x1+th, y1+th, th],
    [x0, y1+th, th],
    [x0, 0, th]
];

linear_extrude(13) {
    hull() {
        translate([profile[0].x, profile[0].y]) circle(d=profile[0].z, $fs=nozzle_d/2);
        translate([profile[1].x, profile[1].y]) circle(d=profile[1].z, $fs=nozzle_d/2);
    }
    hull() {
        translate([profile[1].x, profile[1].y]) circle(d=profile[1].z, $fs=nozzle_d/2);
        translate([profile[2].x, profile[2].y]) circle(d=profile[2].z, $fs=nozzle_d/2);
    }
    #translate([r, y1+th/2]) circle(d=th, $fs=nozzle_d/2);
    for (theta=[186:6:360]) {
        hull() {
            rotate([0, 0, theta])   translate([r, 0]) circle(d=th, $fs=nozzle_d/2);
            rotate([0, 0, theta-6]) translate([r, 0]) circle(d=th, $fs=nozzle_d/2);
        }
    }
}
