// Spider Dropper
// Adrian McCarthy 2023-02-25

// The assembly is mounted overhead.  A string secured to the spool
// holds a toy spider.  A slow motor turns the big gear, which winds
// the spool, raising the spider.  When the toothless section of the
// drive gear comes around, the winder becomes free wheeling, and the
// weight of the spider will cause the spool to unwind rapidly (the
// drop).  When the teeth again engage, the spider will climb back up.

use <aidgear.scad>

function inch(x) = x * 25.4;
function thou(x) = inch(x/1000);

function corners(l, w, r, center=false) =
    let(
        origin = center ? [0, 0] : [l/2, w/2],
        dx = l/2 - r,
        dy = w/2 - r,
        offsets = [[-dx, -dy], [ dx, -dy], [-dx,  dy], [ dx,  dy]]
    )
    [ for (offset = offsets) origin + offset ];

module for_each_position(positions) {
    for (position=positions) translate(position) children();
}

module slot(l, d, center=false) {
    ends = [ [-l/2, 0], [l/2, 0] ];
    origin = center ? [0, 0] : [l/2, 0];
    translate(origin) hull() for_each_position(ends) circle(d=d);
}

module spider_dropper(drop_distance=inch(24), nozzle_d=0.4) {
    m3_free_d = 3.6;
    m3_head_d = 6.0;
    m3_flange_d = 7.0;
    m3_flange_h = 0.7;
    m4_free_d = 4.5;
    m4_head_d = 8.0;
    m4_head_h = 3.1;
    m5_free_d = 5.5;
    m5_head_d = 10;
    no6_free_d = thou(149.5);
    
    string_d = 2;

    // Key dimensions for "reindeer" motors like those sold by
    // FrightProps and MonsterGuts.
    deer_shaft_d = 7.0;
    deer_shaft_af = 5.5;  // across flats
    deer_shaft_h = 6.2;
    deer_shaft_screw = "M4";  // machine screw
    deer_shaft_screw_l = 10;
    deer_base_d = 21;  // at the face plate.  Tapers down to 17.
    deer_base_h = 5;
    deer_mounting_screw = "M3 self-tapping";  // a #6 would fit
    deer_mounting_screw_l = 12;
    deer_mount_dx1 = 81;  // separation between mounting screws nearest the hub
    deer_mount_dx2 = 57;
    deer_mount_dy1 = 18; // hub to dx1 line
    deer_mount_dy2 = 35 + deer_mount_dy1; // hub to dx2 line
    deer_w = 90;
    deer_l = 90;
    deer_h = 37.6;
    
    deer_motor_mounting_holes = [
        [-deer_mount_dx1/2, -deer_mount_dy1],
        [ deer_mount_dx1/2, -deer_mount_dy1],
        [-deer_mount_dx2/2, -deer_mount_dy2],
        [ deer_mount_dx2/2, -deer_mount_dy2]
    ];
    
    // We make the gears thick enough to completely cover the motor shaft
    // and also recess the head of the shaft screw.
    gear_th = deer_shaft_h + 2 + m4_head_h;

    // The drive gear is connected directly to the motor shaft.  It has
    // teeth 3/4 of the way around, and is toothless on the remaining
    // quarter.  The drive gear turns the winder gear, which is attached
    // to the spool.  We use helical teeth for smooth, quiet operation and
    // durability.  Earlier attempts to use herringbone teeth would jam
    // if there was a slight misalignment when the teeth re-engage after
    // a drop.  Helical gears are more forgiving.
    drive = AG_define_gear(
        iso_module=1.25,
        tooth_count=55,
        thickness=gear_th,
        helix_angle=15,
        herringbone=false
    );
    winder = AG_define_gear(tooth_count=11, mate=drive);
    dx = AG_center_distance(drive, winder);

    spool_turns = 3/4*AG_tooth_count(drive) / AG_tooth_count(winder);
    spool_d = drop_distance / (spool_turns * PI);
    spool_h = 10;
    
    spacer_d = AG_tips_diameter(winder);
    spacer_h = 2*nozzle_d;

    plate_th = deer_base_h - spacer_h;
    plate_l = 4*plate_th + spool_d/2 + dx + AG_tips_diameter(drive)/2;
    plate_offset = (AG_tips_diameter(drive) - spool_d)/4;
    plate_w = max(AG_tips_diameter(drive), spool_d, deer_w) + 1;
    plate_r = 10;

    axle_d = 6;
    axle_l = spool_h + spacer_h + AG_thickness(winder);

    guide_w = min(plate_r, 4*string_d);
    guide_h = axle_l + plate_th - spool_h/2;
    guide_d = string_d + nozzle_d;

    bracket_l = plate_th + plate_l + plate_th;
    bracket_w = plate_w;
    bracket_h = plate_th + deer_h + 3*plate_th;
    
    module deer_motor_spline(h=1) {
        // The shaft of the deer motor is a cylinder with two flattened
        // faces.
        shaped_h = min(h, deer_shaft_h);
        linear_extrude(shaped_h, convexity=10) {
            intersection() {
                circle(d=deer_shaft_d+nozzle_d/2);
                square([deer_shaft_d+nozzle_d/2, deer_shaft_af+nozzle_d/2],
                       center=true);
            }
        }
        // If the desired height is taller than the shaft itself, we'll
        // cap the flattened portion so there's something to tighten the
        // hub screw against.
        passthru_h = min(h-shaped_h, 2);
        if (passthru_h > 0) {
            translate([0, 0, shaped_h-0.1]) {
                linear_extrude(passthru_h+0.2, convexity=10) {
                    circle(d=m4_free_d+nozzle_d, $fs=nozzle_d/2);
                }
            }
            // If there's still more height, we'll make a simple hole to
            // recess the head of the hub screw.
            remainder_h = h - shaped_h - passthru_h;
            if (remainder_h > 0) {
                translate([0, 0, shaped_h + passthru_h]) {
                    linear_extrude(remainder_h+0.1, convexity=10) {
                        circle(d=m4_head_d+nozzle_d, $fs=nozzle_d/2);
                    }
                }
            }
        }
    }

    module deer_motor_mounts() {
        // Cutout for the hub.
        cylinder(h=plate_th+0.1, d=deer_base_d+nozzle_d, center=true);
        
        // Mounting bolt holes.
        d = max(m3_head_d + nozzle_d, m3_flange_d);
        for_each_position(deer_motor_mounting_holes) {
            cylinder(h=plate_th+0.1, d=m3_free_d, center=true, $fs=nozzle_d/2);
            translate([0, 0, 2])
                cylinder(h=plate_th, d=d, center=true, $fs=nozzle_d/2);
        }
    }

    module drive_gear() {
        difference() {
            AG_gear(drive, first_tooth=1, last_tooth=ceil(0.75*AG_tooth_count(drive)));
            translate([0, 0, -0.1])
                deer_motor_spline(h=AG_thickness(drive)+0.1);
        }
    }
   
    module spool_assembly() {
        module spacer() {
            translate([0, 0, -0.1])
                cylinder(h=spacer_h+0.2, d=spacer_d, $fs=nozzle_d/2);
        }

        module spool() {
            module pocket() {
                string_r = string_d/2;
                knot_r   = 4*string_r;
                post_r   = 1.5*string_r;
                dr = knot_r - post_r;
                r0 = 0;
                r1 = post_r;
                r2 = r1 + dr/2;
                r3 = knot_r;
                y0 = spool_h/4;
                y1 = y0 + dr/2;
                y2 = spool_h;
                y3 = y2 + nozzle_d;
                translate([spool_d/2-knot_r-plate_th, 0, 0]) union() {
                    rotate_extrude(convexity=8, $fs=nozzle_d/2) {
                        polygon([
                            [r0, y3],
                            [r0, y2],
                            [r1, y2],
                            [r1, y1],
                            [r2, y0],
                            [r3, y1],
                            [r3, y3]
                        ]);
                    }
                    translate([r2, 0, spool_h/2]) rotate([0, 90, -45]) {
                        linear_extrude(knot_r+plate_th, convexity=8) {
                            rotate([0, 0, 45])
                                square(string_d*cos(45), center=true);
                        }
                    }
                }
            }

            difference() {
                rotate_extrude(convexity=10, $fa=5) difference() {
                    square([spool_d/2+2, spool_h-spacer_h]);
                    translate([spool_d/2+spool_h, (spool_h-spacer_h)/2])
                        scale([1, 0.5]) circle(r=spool_h, $fs=nozzle_d/2);
                }
                // The string is secured to the spool in the pocket.
                pocket();
            }
        }
        
        difference() {
            union() {
                AG_gear(winder);
                translate([0, 0, AG_thickness(winder)]) {
                    spacer();
                    translate([0, 0, spacer_h]) {
                        spool();
                    }
                }
            }
            translate([0, 0, -0.1])
                cylinder(h=axle_l+0.2, d=axle_d+nozzle_d, $fs=nozzle_d/2);
        }
    }
    
    module plate() {
        $fs = nozzle_d/2;

        module axle() {
            difference() {
                union() {
                    cylinder(h=spacer_h+0.1, d=AG_root_diameter(winder));
                    translate([0, 0, spacer_h]) {
                        cylinder(h=axle_l+0.1, d=axle_d, $fs=nozzle_d/2);
                        translate([0, 0, axle_l]) {
                            cylinder(h=nozzle_d, d1=axle_d, d2=axle_d+2*nozzle_d);
                            translate([0, 0, nozzle_d]) {
                                cylinder(h=plate_th, d1=axle_d+2*nozzle_d, d2=axle_d-2*nozzle_d);
                            }
                        }
                    }
                }
                translate([0, 0, spacer_h+axle_l+plate_th/6]) {
                    cylinder(h=3*plate_th, d=axle_d/2, center=true);
                    cube([2.25*nozzle_d, axle_d+2*nozzle_d, 3*plate_th], center=true);
                    rotate([0, 0, 90])
                        cube([2.25*nozzle_d, axle_d+2*nozzle_d, 3*plate_th], center=true);
                }
            }
        }
        
        module guide() {
            rotate([90, 0, 0]) linear_extrude(plate_th) {
                difference() {
                    hull() {
                        translate([-guide_w/2, 0]) square([guide_w, plate_th]);
                        translate([0, guide_h]) circle(d=guide_w);
                    }
                    translate([0, guide_h]) {
                        hull() {
                            circle(d=guide_d);
                            translate([0, string_d/4]) rotate([0, 0, 45])
                                square(guide_d*cos(45), center=true);
                        }
                    }
                }
            }
        }

        difference() {
            translate([plate_offset, 0, 0]) {
                c = corners(plate_l, plate_w, plate_r, center=true);
                linear_extrude(plate_th, convexity=8, center=true) {
                    difference() {
                        hull() for_each_position(c) circle(r=plate_r);
                        for_each_position(c) circle(d=m5_free_d+nozzle_d);
                    }
                }
            }
            translate([dx/2, 0, 0]) rotate([0, 0, -90]) deer_motor_mounts();
        }

        translate([-dx/2, 0, plate_th/2-0.1]) axle();

        translate([-(dx+spool_d)/2, -spool_d/2, -plate_th/2])
            rotate([0, 0, 90]) guide();
        
        translate([dx/2+AG_tips_diameter(drive)/2, 0, plate_th/2-0.1])
            rotate([0, 0, -90])
                linear_extrude(1, center=true, convexity=10)
                    text("Prop Dropper", size=6, halign="center", valign="bottom");
    }
    
    module bracket() {
        difference() {
            translate([-bracket_l/2, plate_w/2, 0])
            union() {
                translate([0, -plate_w/2, 0]) rotate([90, 0, 0])
                linear_extrude(plate_w, center=true, convexity=10) {
                    difference() {
                        square([bracket_l, bracket_h]);
                        translate([plate_th, plate_th])
                            square([plate_l, deer_h]);
                        translate([2*plate_th, plate_th+deer_h])
                            square([plate_l-2*plate_th, 3*plate_th]);
                        translate([plate_th-nozzle_d/2, bracket_h-2*plate_th-nozzle_d/2])
                            square([plate_l+nozzle_d, plate_th+nozzle_d]);
                    }
                }
                cube([bracket_l, plate_th, bracket_h]);
            }
            translate([0, 0, bracket_h/2]) {
                rotate([90, 0, 0]) rotate([0, 90, 0]) {
                    linear_extrude(bracket_l+0.2, convexity=10, center=true)
                        slot(l=bracket_w/3, d=no6_free_d, center=true, $fs=nozzle_d/2);
                }
            }
            translate([0, 0, -0.1]) rotate([0, 0, 90]) {
                linear_extrude(plate_th+0.2, convexity=10)
                    slot(l=bracket_w/3, d=no6_free_d, center=true, $fs=nozzle_d/2);
            }
            translate([0, 0.1, bracket_h/2]) rotate([90, 90, 0]) {
                linear_extrude(bracket_w+2*plate_th+0.2, convexity=10, center=true)
                    slot(l=bracket_h/3, d=no6_free_d, center=true, $fs=nozzle_d/2);
            }
        }
    }

    if ($preview) {
        translate([0, 0, plate_th/2]) plate();
        translate([dx/2, 0, plate_th + spacer_h]) drive_gear();
        translate([-dx/2, 0, plate_th + spacer_h]) spool_assembly();
        //translate([plate_offset, 0, -(bracket_h-2*plate_th)]) bracket();
    } else {
        translate([0, 0, plate_th/2]) plate();
        translate([AG_tips_diameter(drive)/2+1, (plate_w + AG_tips_diameter(drive))/2+1, 0])
            drive_gear();
        translate([-(spool_d+3)/2, (plate_w + spool_d)/2+3, spool_h + AG_thickness(winder)])
            rotate([180, 0, 0])
                spool_assembly();
//        translate([-(bracket_h+2), (bracket_l-plate_w)/2, plate_w/2+plate_th])
//            rotate([-90, 0, 90])
//                bracket();
    }
}

spider_dropper();
