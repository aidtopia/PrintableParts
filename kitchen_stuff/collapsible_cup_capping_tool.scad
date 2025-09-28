// A ring to make it easier to secure lid on expandable cup.

nozzle_d = 0.4;
h = 20;
th = 2.4;
id = 76;
od = id + 2*th;

$fs = nozzle_d/2;
$fa = 3;

module donut() {
    rotate_extrude(convexity=4) {
        translate([od/2-nozzle_d, 0]) scale([0.75, 1]) circle(r=th);
    }
}

difference() {
    union() {
        translate([0, 0, th]) donut();
        translate([0, 0, h-th]) donut();
        linear_extrude(h) circle(d=od);
    }
    translate([0, 0, -1]) linear_extrude(h+2) circle(d=id);
}

