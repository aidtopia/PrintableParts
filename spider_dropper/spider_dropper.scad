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

module spider_dropper(drop_distance=24*25.4, nozzle_d=0.4) {
    drive = AG_define_gear(iso_module=1.25, tooth_count=55, thickness=8, helix_angle=15, herringbone=true);
    spool = AG_define_gear(tooth_count=11, mate=drive);
    dx = AG_center_distance(drive, spool);

    spool_turns = 3/4*AG_tooth_count(drive) / AG_tooth_count(spool);
    spool_dia = drop_distance / (spool_turns * PI);
    spool_h = 10;
    
    axle_d = 6;
    bore_d = axle_d + nozzle_d;

    plate_w = dx + max(spool_dia, AG_tips_diameter(drive));
    plate_h = max(AG_tips_diameter(drive), spool_dia) + 1;
    plate_th = 1.8;
    
    spacer_h = 2*nozzle_d;
    spacer_d = AG_tips_diameter(spool);

    module tt_motor_shaft(h=1) {
        linear_extrude(h, convexity=10) {
            intersection() {
                circle(d=5.4+nozzle_d);
                square([5.4+nozzle_d, 3.7+nozzle_d], center=true);
            }
        }
    }
    
    module deer_motor_shaft(h=1) {
        shaped_h = min(h, 6.2);
        linear_extrude(shaped_h, convexity=10) {
            intersection() {
                circle(d=7.1+nozzle_d);
                square([7.1+nozzle_d, 5.7+nozzle_d], center=true);
            }
        }
        passthru_h = min(h-shaped_h, 1);
        translate([0, 0, shaped_h-0.1]) {
            linear_extrude(passthru_h+0.2, convexity=10) {
                circle(d=4.5+nozzle_d);
            }
        }
        remainder_h = h - shaped_h - passthru_h;
        if (remainder_h >= 0) {
            translate([0, 0, shaped_h + passthru_h]) {
                linear_extrude(remainder_h+0.1, convexity=10) {
                    circle(d=8+nozzle_d);
                }
            }
        }
    }

    module drive_gear() {
        difference() {
            AG_gear(drive, first_tooth=1,
                    last_tooth=ceil(0.75*AG_tooth_count(drive)));
            translate([0, 0, -1]) deer_motor_shaft(h=10);
        }
    }
   
    module spool() {
        difference() {
            union() {
                AG_gear(spool);

                translate([0, 0, AG_thickness(spool)]) {
                    translate([0, 0, -0.1])
                        cylinder(h=spacer_h+0.1, d=spacer_d);
                
                    translate([0, 0, spacer_h]) {
                        rotate_extrude(convexity=10) difference() {
                            square([spool_dia/2+2, spool_h-spacer_h]);
                            translate([spool_dia/2+spool_h, (spool_h-spacer_h)/2]) circle(r=spool_h);
                        }
                    }
                }
            }
            translate([0, 0, -0.1])
                cylinder(h=spool_h+AG_thickness(spool)+0.2, d=bore_d);
        }
    }
    
    module plate() {
        total_h = AG_thickness(spool) + spacer_h + spool_h + 2*plate_th;
        difference() {
            union() {
                cube([plate_w, plate_h, plate_th], center=true);

                translate([0, 0, plate_th/2-0.1]) {
                    translate([dx/2, 0, 0]) {
                        cylinder(h=spacer_h+0.1, d=spacer_d);
                    }
                    translate([-dx/2, 0, 0]) {
                        cylinder(h=total_h, d=axle_d);
                        cylinder(h=spacer_h+0.1, d=spacer_d);
                    }
                }
            }
            translate([dx/2, 0, -plate_th/2-0.2])
                cylinder(h=total_h, d=7.1+nozzle_d);
        }
    }

    if ($preview) {
        translate([0, 0, plate_th/2]) plate();
        translate([dx/2, 0, plate_th + spacer_h]) drive_gear();
        translate([-dx/2, 0, plate_th + spacer_h]) spool();
    } else {
        translate([0, 0, plate_th/2]) plate();
        translate([AG_tips_diameter(drive)/2+1, (plate_h + AG_tips_diameter(drive))/2+1, 0])
            drive_gear();
        translate([-(spool_dia+3)/2, (plate_h + spool_dia)/2+3, spool_h + AG_thickness(spool)]) rotate([180, 0, 0]) spool();
    }
}

spider_dropper($fa=6, $fs=0.2);

module deer_motor_mount(th=3, nozzle_d=0.4) {
    deer_shaft_d = 7.1;
    deer_shaft_af = 5.7;  // across flats
    deer_shaft_h = 6.2;
    deer_shaft_screw = "M4";  // machine screw
    deer_shaft_screw_l = 10;
    deer_base_d = 21;  // at the face plate.  Tapers down to 17.
    deer_base_h = 3.7;
    deer_mounting_screw = "M3 self-tapping";  // a #6 would fit
    deer_mounting_screw_l = 12;
    deer_mount_dx1 = 81;  // separation between mounting screws nearest the hub
    deer_mount_dx2 = 57;
    deer_mount_dy1 = 18; // hub to dx1 line
    deer_mount_dy2 = 35; // dx1 line to dx2 line
    deer_h = 37.6;

    deer_mount_free_d = 3.6 + nozzle_d;
    deer_mount_extra_d = max(2*th, 4);
    deer_mount_d = deer_mount_free_d + deer_mount_extra_d;

    cutout = [
        [2*th, -(deer_mount_dy1+3*th)],
        [2*th, -(deer_mount_dy1+deer_mount_dy2-3*th)],
        [deer_mount_dx2/2-3*th, -(deer_mount_dy1+deer_mount_dy2-3*th)],
        [deer_mount_dx1/2-4*th, -(deer_mount_dy1+3*th)],
    ];

    linear_extrude(min(th, deer_base_h), convexity=10) {
        difference() {
            hull() {
                circle(d=deer_base_d + deer_mount_extra_d);
                translate([0, -deer_mount_dy1]) {
                    translate([-deer_mount_dx1/2, 0]) circle(d=deer_mount_d);
                    translate([ deer_mount_dx1/2, 0]) circle(d=deer_mount_d);
                    translate([0, -deer_mount_dy2]) {
                        translate([-deer_mount_dx2/2, 0]) circle(d=deer_mount_d);
                        translate([ deer_mount_dx2/2, 0]) circle(d=deer_mount_d);
                    }
                }
            }
            circle(d=deer_base_d + nozzle_d);
            translate([0, -deer_mount_dy1]) {
                translate([-deer_mount_dx1/2, 0])
                    circle(d=deer_mount_free_d, $fs=nozzle_d/2);
                translate([ deer_mount_dx1/2, 0])
                    circle(d=deer_mount_free_d, $fs=nozzle_d/2);
                translate([0, -deer_mount_dy2]) {
                    translate([-deer_mount_dx2/2, 0])
                        circle(d=deer_mount_free_d, $fs=nozzle_d/2);
                    translate([ deer_mount_dx2/2, 0])
                        circle(d=deer_mount_free_d, $fs=nozzle_d/2);
                }
            }
            // Just reducing the material needed:
            polygon(cutout);
            mirror([1, 0, 0]) polygon(cutout);
        }
    }
}

//deer_motor_mount(th=1.2);
