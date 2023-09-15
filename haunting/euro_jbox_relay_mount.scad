// Mount for Relay Module in European-style Junction Box
// Adrian McCarthy 2023-08-28
//
// European screw terminal strips have holes between each connection that
// fit over vertical pins at the bottom of the junction box.  I want to
// mount a single relay module there instead.  This part holds the relay
// module just above the box's pins.
//
// Designed for
// junction box:  https://www.amazon.com/gp/product/B07FDKH4G3
// relay module:  https://www.amazon.com/gp/product/B07BVXT1ZK
//
// I like the junction box.  I'm not sure I'd recommend this relay module.

nozzle_d = 0.4;
th = 1.2;

// The jbox
pin_d = 3;
pin_h = 9;
pin_spacing = 10;
pin_bias = 3;

// The relay module
module_w = 25.4;
module_l = 33.0;
module_th = 1;
screw_d = 3;
screw_r = screw_d/2;
screw_offset = 0.5;  // inward from edges
boss_d = screw_d + 1;
boss_r = boss_d/2;

dx = (module_l - 2*screw_offset - 2*screw_r) / 2;
dy = (module_w - 2*screw_offset - 2*screw_r) / 2;

module corners() {
    translate([-dx, -dy]) children();
    translate([-dx,  dy]) children();
    translate([ dx, -dy]) children();
    translate([ dx,  dy]) children();
}

module standoff() {
    rotate_extrude(convexity=6, $fs=nozzle_d/2)
        polygon([
            [0, 0],
            [boss_r, 0],
            [boss_r, pin_h],
            [screw_r, pin_h],
            [screw_r, pin_h + module_th],
            [screw_r + 0.2, pin_h + module_th + 0.2],
            [screw_r, pin_h + module_th + 0.2 + th],
            [0, pin_h + module_th + 0.2 + th]
        ]);
}

linear_extrude(th, convexity=6) {
    difference() {
        hull() corners() circle(d=boss_d, $fs=nozzle_d/2);
        translate([0, pin_bias-pin_spacing/2]) circle(d=pin_d, $fs=nozzle_d/2);
        translate([0, pin_bias+pin_spacing/2]) circle(d=pin_d, $fs=nozzle_d/2);
    }
}

corners() standoff();
