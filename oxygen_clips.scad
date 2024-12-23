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

// The Command-brand double-sided tape strips do not stick reliably
// to PLA nor to PETG.  So here's a nail-on version:

module oxygen_clip(nozzle_d = 0.4) {
    $fs = nozzle_d/2;

    id = 6.5 + nozzle_d;
    th = 2.4;
    hook_l = 16.5;
    nail_d = 2;
    nail_head_d = 4;
    tab_l = 3*nail_head_d;
    plate_l = hook_l + tab_l;
    plate_w = 12.5;

    od = id + 2*th;

    r = (id+od)/2/2;
    x0 = 0 - r;
    x1 = x0 + plate_w;
    y0 = 0 - (r + nozzle_d);
    y1 = 0 + (r + nozzle_d);

    profile = [
        [x1, y1+th, th],
        [x0, y1+th, th],
        [x0, 0, th]
    ];

    // Ceiling plate
    translate([0, y1]) {
        difference() {
            linear_extrude(plate_l, convexity=8) {
                union() {
                    hull() {
                        translate([x1, th]) circle(d=th);
                        translate([x0, th]) circle(d=th);
                    }
                    translate([0, 0.75*th]) {
                        translate([r+th, 0]) circle(d=th);
                        hull() {
                            translate([-nail_head_d/2, 0]) circle(d=th);
                            translate([ nail_head_d/2, 0]) circle(d=th);
                        }
                    }
                }
            }
            translate([0, th, plate_l - 1/3*tab_l]) {
                rotate([-90, 0, 0]) {
                    cylinder(d=nail_d+nozzle_d, h=2*th, center=true);
                    translate([0, 0, -0.75*th]) {
                        cylinder(d=nail_head_d+nozzle_d, h=0.25*th);
                    }
                }
            }
        }
    }

    // The j-shaped hook for the tubing.
    linear_extrude(hook_l + nozzle_d, convexity=8) {
        hull() {
            translate([x0, y1+th]) circle(d=th);
            translate([x0, 0    ]) circle(d=th);
        }
        da = 6;
        for (theta=[180+da:da:360]) {
            hull() {
                rotate([0, 0, theta])    translate([r, 0]) circle(d=th);
                rotate([0, 0, theta-da]) translate([r, 0]) circle(d=th);
            }
        }
    }
}

module thumbtack(nozzle_d=0.4) {
    tack_od = 10.6;
    tack_cap_th = 1.1;
    tack_reach = 5.5;  // from below the cap to the beginning of the taper
    tack_taper_len = 2.1;  // length of the pointy bit
    tack_shaft_d = 1.0;
    
    linear_extrude(tack_cap_th)
        circle(d=tack_od, $fs=nozzle_d/2);
    linear_extrude(tack_cap_th + tack_reach)
        circle(d=tack_shaft_d, $fs=nozzle_d/2);
    translate([0, 0, tack_cap_th + tack_reach])
        linear_extrude(tack_taper_len, scale=0.01)
            circle(d=tack_shaft_d, $fs=nozzle_d/2);
}

function round_up(value, increment=0.4) = ceil(value / increment) * increment;

module thumbtack_mount(nozzle_d=0.4) {
    tack_od = 10.6;
    tack_cap_th = 1.1;
    tack_reach = 5.5;  // from below the cap to the beginning of the taper
    tack_taper_len = 2.1;  // length of the pointy bit
    tack_shaft_d = 1.0;

    tack_recess_d = tack_od + nozzle_d;
    recess_wall_d = tack_recess_d + 2*nozzle_d;

    mount_th = round_up(1.2 + tack_cap_th, 0.3);
    mount_w  = max(12, round_up(recess_wall_d + 2*mount_th, 1));
    mount_l = 16;
    mount_lift = nozzle_d;
    flare = mount_th - mount_lift;
    difference() {
        rotate([90, 0, 0])
            linear_extrude(mount_l, center=true, convexity=4)
                polygon([
                    [ mount_w/2 - flare, 0],
                    [ mount_w/2 - flare, mount_lift],
                    [ mount_w/2        , mount_th + mount_lift],
                    [-mount_w/2        , mount_th + mount_lift],
                    [-mount_w/2 + flare, mount_lift],
                    [-mount_w/2 + flare, 0]
                ]);
        translate([0, 0, -1])
            cylinder(h=mount_th+2, d=tack_shaft_d+nozzle_d, $fs=nozzle_d/2);
        translate([0, 0, mount_th-tack_cap_th-0.6])
            cylinder(h=tack_cap_th+mount_th, d=tack_recess_d, $fs=nozzle_d/2);
    }
}

for (row = [0:3]) {
    for (col = [0:3]) {
        translate([col*16, row*16, 0]) oxygen_clip();
    }
}



