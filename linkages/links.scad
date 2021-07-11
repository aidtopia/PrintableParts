// ProtoLinks
// Copyright 2020-2021 Adrian McCarthy
//
// A kit for prototyping mechanical linkages.

xhat = [1, 0, 0];
yhat = [0, 1, 0];
zhat = [0, 0, 1];

// We want to interop with the shaft on the TT motors, which are toy
// DC motors with gearboxes sold in various places, including
// Adafruit.com.  These dimensions come from the diagram on the
// Adafruit site and were confirmed with calipers.
// https://www.adafruit.com/product/3777
tt_shaft_d = 5.4;
tt_shaft_w = 3.7;
tt_bore_d = 1.95;

// Bare toy DC motor shafts are typically 2mm, but a print test shows
// we need 2.4mm for a snug fit, which makes sense for a 0.4 mm nozzle.
dc_motor_shaft_d = 2.4;

// All other dimensions are derived from the shaft dimensions, which
// will give us parts that can be combined in countless ways.
bar_th = tt_shaft_w;
bar_w = 1.75 * tt_shaft_d;
unit_size = (2*bar_w + tt_shaft_d) / 2;
pin_h = bar_th;
pinhole_d = max(dc_motor_shaft_d, tt_bore_d);

module axle(h=1, taper=0.0, clearance=0.0, ridges_y=[]) {
    axle_r = (tt_shaft_d + clearance)/2;
    taper_dx = taper;
    taper_dy = abs(2*taper);
    rotate_extrude(convexity=10)
        polygon(points=[
            [0, -0.01],
            [axle_r - taper_dx, -0.01],
            [axle_r, taper_dy],
            for (ry = ridges_y) each [
                [axle_r, ry-0.2],
                [axle_r + 0.3, ry],
                [axle_r, ry+0.2]
            ],
            [axle_r, h - taper_dy],
            [axle_r - taper_dx, h + 0.01],
            [0, h + 0.01]
        ]);
}

// `tt_shaft` matches the output shaft of the TT motor's gear box.
// For a snug fit, set `clearance` to 0.3 when boring a matching hole.
// Use 0.4 for a looser fit.
module tt_shaft(h=1, taper=0.0, clearance=0.0, ridges_y=[]) {
    shaft_d = tt_shaft_d + clearance;
    shaft_w = tt_shaft_w + clearance;
    // The shaft is a cylinder flattened on opposite sides.
    intersection() {
        axle(h=h, taper=taper, clearance=clearance, ridges_y=ridges_y);
        translate([0, 0, h/2]) cube([shaft_w, 1.1*shaft_d, h + 0.04], center=true);
    }
}

module link(size_or_pattern=5) {
    module bar() {
        hull() {
            cylinder(d=bar_w, h=bar_th);
            translate((units - 1) * unit_size * xhat)
                cylinder(d=bar_w, h=bar_th);
        }
    }
    
    module pin() {
        shaft_h = bar_th + pin_h;
        translate(0.01*zhat) tt_shaft(h=shaft_h, taper=0.3, clearance=0, ridges_y=[bar_th + pin_h/2]);
    }
    
    module pinhole() {
        shaft_h = bar_th + pin_h;
        translate(-1*zhat) cylinder(d=pinhole_d, h=shaft_h + 2, $fn=16);
    }
    
    module bearing() {
        axle(h=bar_th, taper=-0.3, clearance=0.4, ridges_y=[bar_th/2], $fn=32);
    }
    
    module slot() {
        tt_shaft(h=bar_th, taper=-0.3, clearance=0.4, ridges_y=[bar_th/2]);
    }

    units = is_num(size_or_pattern) ? size_or_pattern : len(size_or_pattern);
    pattern = is_string(size_or_pattern) ? size_or_pattern :
        [if (units > 0) "^",
         if (units > 2) for (i = [1:units - 2]) "*",
         if (units > 1) "v"];
    echo(units, pattern);
    difference() {
        union() {
            bar();
            for (i = [0:units-1]) {
                c = pattern[i];
                if (c == "^") {
                    translate(i*unit_size*xhat) pin($fn=48);
                } else if (c == "-") {
                    translate(i*unit_size*xhat) rotate(90*zhat) pin($fn=48);
                }
            }
        }
        for (i = [0:units-1]) {
            c = pattern[i];
            if (c == "^" || c == "-") {
                translate(i*unit_size*xhat) pinhole();
            } else if (c == "*") {
                translate(i*unit_size*xhat) bearing();
            } else if (c == "v") {
                translate(i*unit_size*xhat) slot();
            }
        }
    }
}

if (1) {
    longest=3;
    for (i = [1:longest]) {
        translate(i*(bar_w + 1)*yhat) union() {
            link(i);
            if (i < longest) {
                translate(i*unit_size*xhat) link(longest-i);
            }
        }
    }

    link("^v-v^");
} else {
    difference() {
        translate([-4, -4, 0.01]) cube([8, 8, bar_th - 0.01]);
        axle(h=2*bar_th, taper=-0.2, clearance=0.4,
             ridges_y=[for (ry=[bar_th/2:bar_th:2*bar_th]) ry]);
    }

    intersection() {
        axle(h=2*bar_th, taper=0.1, ridges_y=[for (ry=[bar_th/2:bar_th:2*bar_th]) ry]);
        translate(bar_th*zhat) cube([tt_shaft_w, tt_shaft_d*2, 2*bar_th], center=true);
    }
}

