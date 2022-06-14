// DIN rail mount
// Adrian McCarthy 2022-06-09

// NOT READY FOR RE-USE

// A generalized version of code I wrote for wire_spool_holder.scad.

use <aidutil.scad>

// Modifies almost any widget (provided as children to the invocation of
// this module) to make it mountable to 35mm "top-hat" style DIN rail
// (IEC/EN 60715).  This should work with either the 7.5 or 15 mm depth.
module AD_din_rail_profile(depth=7.5) {
    back_x = 0;
    front_x = back_x - depth;
    top_y = 35/2;
    bend_y = top_y - 5;
    th = 1;
    points = [
        [back_x - th,   bend_y],
        [front_x,       bend_y],
        [front_x,       top_y],
        [front_x + th,  top_y],
        [front_x + th,  bend_y + th],
        [back_x,        bend_y + th],
    
        [back_x,        -(bend_y + th)],
        [front_x + th,  -(bend_y + th)],
        [front_x + th,  -(top_y)],
        [front_x,       -(top_y)],
        [front_x,       -(bend_y)],
        [back_x - th,   -(bend_y)]
    ];
    polygon(points);
}

module AD_din_rail(length=100, depth=7.5, center=false) {
    assert(depth == 7.5 || depth == 15,
           "AD: 35mm top hat rail must be 7.5 or 15 mm deep");

    // Actual slot patterns vary by manufacturer and model.
    module slots(length, slot_d=4.5, slot_l=12, slot_interval=20) {

        module slot(d, l) {
            dx = (l - d) / 2;
            rotate([0, 90, 0])
            linear_extrude(depth, convexity=4, center=true)
            hull() {
                translate([ dx, 0, 0]) circle(d=d, $fs=0.2);
                translate([-dx, 0, 0]) circle(d=d, $fs=0.2);
            }
        }

        for (z = [slot_interval/2:slot_interval:length/2]) {
            translate([0, 0,  z]) slot(slot_d, slot_l);
            translate([0, 0, -z]) slot(slot_d, slot_l);
        }
    }

    translate([0, 0, center ? 0 : length/2])
    difference() {
        linear_extrude(length, convexity=4, center=true)
            AD_din_rail_profile(depth=depth);
        slots(length);
    }
}

module AD_din_rail_mountable(depth=7.5, nozzle_d=0.4) {
    unit_width = 18;  // per Wikipedia
    
    // The cutout is the envelope of a rail twisted and slid
    // out of the bottom of the widget.
    module din_cutout(length=250, center=false) {
        translate([0, 0, center ? 0 : length/2])
        linear_extrude(length, convexity=4, center=true) {
            // the twist
            offset(delta=nozzle_d/2) projection() 
                translate([-depth, 35/2, 0])
                    linear_extrude(10, twist=-20)
                        translate([depth, -35/2])
                            AD_din_rail_profile(depth=depth);
            // the slide
            translate([-depth, 35/2, 0])
                for (i = [0:1:10])
                    rotate([0, 0, 20]) translate([0, -i])
                        translate([depth, -35/2])
                            AD_din_rail_profile(depth=depth);
        }
    }
    
    module slide_clip_profile() {
        profile = 
        polygon(profile);
    }
    
    module slide_clip(grip=10, delta=0) {
        extent = -(14 + grip);
        intersection() {
            // the end of the clip
            linear_extrude(20, convexity=10)
                offset(delta=delta)
                    polygon([
                        [-3,  0],
                        [-5,  2],
                        [-2,  5],
                        [ 2,  5],
                        [ 5,  2],
                        [ 3,  0]
                    ]);

            // the side of the clip
            translate([-7, 0, 0]) rotate([0, 90, 0])
            linear_extrude(14, convexity=10)
                offset(delta=delta)
                    polygon([
                        [ 0,  2-nozzle_d/2],
                        [ 0,  0],
                        [extent, 0],
                        [extent, 2],
                        [-14.5, 2],
                        [-14, 2.5],
                        [-14, 5],
                        [-4, 5],
                        [-2, 3],
                        [-2, 2-nozzle_d/2]
                    ]);

            // the top of the clip
            rotate([-90, 0, 0])
            linear_extrude(5, convexity=10)
                offset(delta=delta)
                    polygon([
                        [ -5,   0 ],
                        [ -5,  -5 ],
                        [ -3,  -5 ],
                        [ -3, -11 ],
                        [ -5, -11 ],
                        [ -5, extent ],
                        [  5, extent ],
                        [  5, -11 ],
                        [  3, -11 ],
                        [  3,  -5 ],
                        [  5,  -5 ],
                        [  5,   0 ]
                    ]);

        }
    }

    difference() {
        // Ensure the widget has enough material to span the rail
        union() {
            children();
            translate([-unit_width/2, -60/2, 0]) cube([unit_width, 50, 5]);
        }
        // Cut out notches for the rails to pass through.
        translate([0, 0, -(depth-3)]) rotate([0, 90, 0])
            din_cutout(length=100, center=true);
        
        // Make room for the slide clip to slide.
        for (dy = [0:1:4])
            translate([0, -35/2 + dy, 0]) rotate([90, 0, 0])
                slide_clip(delta=nozzle_d/2);

        // Remove the center of the bridge over the lower rail to avoid
        // sagging that could interfere with a tight fit.
        translate([0, -(35-5)/2, 5]) cube([10, 5+nozzle_d, 4], center=true);
    }
    translate([0, -35/2 + 1, 0]) rotate([90, 0, 0])
        slide_clip();
    
}
    
module widget1() {
    translate([0, 0, 5/2]) difference() {
        cube([36, 50, 5], center=true);
        translate([0, 0, 2]) cube([36-4, 50-4, 5], center=true);
    }
}

module widget2() {
    intersection() {
        translate([0, 0, 10]) sphere(r=15);
        translate([0, 0, 15]) cube(2*15, center=true);
    }
}

din_depth = 7.5;
//AD_din_rail_profile(depth=din_depth);
//AD_din_rail(depth=din_depth, center=true);
color("green")
//translate([-20, 0, 0])
AD_din_rail_mountable(depth=din_depth) {
//    widget1();
}
//color("yellow") translate([20, 0, 0]) AD_din_rail_mountable(depth=din_depth) { widget2(); }


if (false) {
color("yelow") translate([-5.1, -35, 0]) difference() {
    cube([10.2, 20, 7]);
    translate([-1, 4.5, 3.8]) cube([10.2+2, 22, 1.4]);
    translate([-1, 17, 1.8]) cube([10.2+2, 5, 2.2]);
}
}


if ($preview) {
    translate([0, 0, -(din_depth - 3)]) rotate([0, 90, 0])
        AD_din_rail(center=true);
}
