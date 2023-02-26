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

    module drive_gear() {
        difference() {
            AG_gear(drive);
            translate([0, 0, -1]) {
                rotate([0, 0, 180/AG_tooth_count(drive)]) intersection() {
                    cube(AG_tips_diameter(drive)/2);
                    difference() {
                        cylinder(h=10, d=AG_tips_diameter(drive)+1);
                        translate([0, 0, -1]) {
                            cylinder(h=12, d=AG_root_diameter(drive)-1);
                        }
                    }
                }
            }
            translate([0, 0, -1]) tt_motor_shaft(h=10);
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
                cylinder(h=total_h, d=axle_d);
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
