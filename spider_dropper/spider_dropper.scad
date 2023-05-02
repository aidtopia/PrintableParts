// Spider Dropper
// Adrian McCarthy 2023-02-25

// The assembly is mounted overhead.  A string secured to the spool
// holds a toy spider.  A slow motor turns the big gear, which winds
// the spool, raising the spider.  When the toothless section of the
// drive gear comes around, the spool becomes free wheeling, and the
// weight of the spider will cause the spool to unwind rapidly (the
// drop).  When the teeth again engage, the spider will climb back
// up.

use <aidgear.scad>

function inch(x) = x * 25.4;
function thou(x) = inch(x/1000);

module spider_dropper(drop_distance=inch(24), nozzle_d=0.4) {
    m3_free_d = 3.6;
    m3_head_d = 6.0;
    m4_free_d = 4.5;
    m4_head_d = 8.0;
    m4_head_h = 3.1;
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
    // and recess the head of the shaft screw.
    gear_th = deer_shaft_h + 2 + m4_head_h;

    // The drive gear is connected directly to the motor shaft.  It has
    // teeth 75% of the way around, and is toothless on the remaining
    // quarter.  The drive gear turns out winder gear, which is attached
    // to the spool.  We use helical teeth for strength and to pull the
    // gears into alignment.  Earlier attempts to use herringbone teeth
    // would often jam if there was a slight misalignment when the teeth
    // re-engage after a drop.  The helical gears are more forgiving.
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
    spool_dia = drop_distance / (spool_turns * PI);
    spool_h = 10;
    
    axle_d = 6;
    bore_d = axle_d + nozzle_d;

    spacer_h = 2*nozzle_d;

    plate_th = deer_base_h - spacer_h;
    plate_w = 2*plate_th + spool_dia/2 + dx + AG_tips_diameter(drive)/2 + plate_th;
    plate_offset = (AG_tips_diameter(drive) - spool_dia)/4;
    plate_h = max(AG_tips_diameter(drive), spool_dia, deer_w) + 1;
    plate_r = 10;

    bracket_w = plate_th + plate_w + plate_th;
    bracket_h = plate_th + deer_h + 3*plate_th;
    
    module deer_motor_shaft(h=1) {
        shaped_h = min(h, deer_shaft_h);
        linear_extrude(shaped_h, convexity=10) {
            intersection() {
                circle(d=deer_shaft_d+nozzle_d/2);
                square([deer_shaft_d+nozzle_d/2, deer_shaft_af+nozzle_d/2],
                       center=true);
            }
        }
        passthru_h = min(h-shaped_h, 2);
        translate([0, 0, shaped_h-0.1]) {
            linear_extrude(passthru_h+0.2, convexity=10) {
                circle(d=m4_free_d+nozzle_d, $fs=nozzle_d/2);
            }
        }
        remainder_h = h - shaped_h - passthru_h;
        if (remainder_h >= 0) {
            translate([0, 0, shaped_h + passthru_h]) {
                linear_extrude(remainder_h+0.1, convexity=10) {
                    circle(d=m4_head_d+nozzle_d, $fs=nozzle_d/2);
                }
            }
        }
    }

    module deer_motor_mounts() {
        for (pos = deer_motor_mounting_holes) {
            translate(pos) children();
        }
    }

    module drive_gear() {
        difference() {
            AG_gear(drive, first_tooth=1, last_tooth=ceil(0.75*AG_tooth_count(drive)));
            translate([0, 0, -0.1]) deer_motor_shaft(h=AG_thickness(drive)+0.1);
        }
    }
   
    module spool_assembly() {
        difference() {
            union() {
                AG_gear(winder);

                translate([0, 0, AG_thickness(winder)]) {
                    translate([0, 0, -0.1])
                        cylinder(h=spacer_h+0.2, d=AG_tips_diameter(winder), $fs=nozzle_d/2);
                
                    translate([0, 0, spacer_h]) {
                        difference() {
                            rotate_extrude(convexity=10, $fa=5) difference() {
                                square([spool_dia/2+2, spool_h-spacer_h]);
                                translate([spool_dia/2+spool_h, (spool_h-spacer_h)/2]) circle(r=spool_h, $fs=nozzle_d/2);
                            }
                            // hole for anchoring string to spool
                            translate([spool_dia/2-1, 0, spool_h/2]) {
                                rotate([0, -45, 0]) {
                                    cylinder(h=2*spool_h, d=string_d+nozzle_d, center=true, $fs=nozzle_d/2);
                                }
                            }
                        }
                    }
                }
            }
            translate([0, 0, -0.1])
                cylinder(h=spool_h+AG_thickness(winder)+0.2, d=bore_d, $fs=nozzle_d/2);
        }
    }
    
    module plate() {
        total_h = AG_thickness(winder) + spacer_h + spool_h + plate_th;
        difference() {
            translate([plate_offset, 0, 0]) union() {
                linear_extrude(plate_th, center=true) hull() {
                    translate([-(plate_w/2-plate_r), -(plate_h/2-plate_r)])
                        circle(r=plate_r, $fs=nozzle_d/2);
                    translate([ (plate_w/2-plate_r), -(plate_h/2-plate_r)])
                        circle(r=plate_r, $fs=nozzle_d/2);
                    translate([-(plate_w/2-plate_r),  (plate_h/2-plate_r)])
                        circle(r=plate_r, $fs=nozzle_d/2);
                    translate([ (plate_w/2-plate_r),  (plate_h/2-plate_r)])
                        circle(r=plate_r, $fs=nozzle_d/2);
                }
            }
            translate([dx/2, 0]) rotate([0, 0,-90]) {
                cylinder(h=plate_th+0.1, d=deer_base_d+nozzle_d, center=true, $fs=nozzle_d/2);
                deer_motor_mounts() {
                    cylinder(h=plate_th+0.1, d=m3_free_d, center=true, $fs=nozzle_d/2);
                    translate([0, 0, 2.1])
                        cylinder(h=plate_th+0.1, d=m3_head_d, center=true, $fs=nozzle_d/2);
                }
            }
        }

        translate([0, 0, plate_th/2-0.1]) {
            translate([-dx/2, 0, 0]) {
                cylinder(h=total_h, d=axle_d, $fs=nozzle_d/2);
                cylinder(h=spacer_h+0.1, d=AG_root_diameter(winder));
            }
        }

        guide_w = min(plate_r, 4*string_d);
        guide_h = total_h - string_d;
        guide_d = string_d + nozzle_d;
        translate([-(dx+spool_dia)/2, -spool_dia/2, -plate_th/2]) {
            rotate([90, 0, 90])
            linear_extrude(plate_th) {
                difference() {
                    hull() {
                        translate([-guide_w/2, 0]) square([guide_w, plate_th]);
                        translate([0, guide_h]) circle(d=guide_w, $fs=nozzle_d/2);
                    }
                    translate([0, total_h-string_d]) {
                        hull() {
                            circle(d=guide_d, $fs=nozzle_d/2);
                            translate([0, string_d/4]) rotate([0, 0, 45])
                                square(guide_d*cos(45), center=true);
                        }
                    }
                }
            }
        }
    }
    
    module bracket() {
        difference() {
            translate([-bracket_w/2, plate_h/2, 0])
            union() {
                translate([0, -plate_h/2, 0]) rotate([90, 0, 0])
                linear_extrude(plate_h, center=true, convexity=10) {
                    difference() {
                        square([bracket_w, bracket_h]);
                        translate([plate_th, plate_th]) square([plate_w, deer_h]);
                        translate([2*plate_th, plate_th+deer_h]) square([plate_w-2*plate_th, 3*plate_th]);
                        translate([plate_th-nozzle_d/2, bracket_h-2*plate_th-nozzle_d/2]) square([plate_w+nozzle_d, plate_th+nozzle_d]);
                    }
                }
                //cube([bracket_w, plate_th, bracket_h]);
            }
            // TODO:  holes for mounting screws
        }
    }

    if ($preview) {
        translate([0, 0, plate_th/2]) plate();
        translate([dx/2, 0, plate_th + spacer_h]) drive_gear();
        translate([-dx/2, 0, plate_th + spacer_h]) spool_assembly();
        translate([plate_offset, 0, -(bracket_h-2*plate_th)]) bracket();
    } else {
        translate([0, 0, plate_th/2]) plate();
        translate([AG_tips_diameter(drive)/2+1, (plate_h + AG_tips_diameter(drive))/2+1, 0])
            drive_gear();
        translate([-(spool_dia+3)/2, (plate_h + spool_dia)/2+3, spool_h + AG_thickness(winder)]) rotate([180, 0, 0]) spool_assembly();
        translate([-(bracket_h+2), (bracket_w-plate_h)/2, plate_h/2]) rotate([-90, 0, 90]) bracket();
    }
}

spider_dropper();
