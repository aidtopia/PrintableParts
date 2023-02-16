module clapper_slate(w=60, h=0, th=25.4/4, use_608_bearing=false, nozzle_d=0.4) {
    slate_w = w;
    slate_h = (h > 0) ? h : 3/4 * slate_w;
    slate_th = th;

    bearing_id = 8;
    bearing_w = 7;
    bearing_od = use_608_bearing ? 22 : bearing_id;

    hinge_od = 26;  // = od of 608 bearing + 4;

    arm_l = slate_w;
    arm_h = hinge_od;
    arm_th = max(21.65, 3*bearing_w);

    boss0_x = 0;
    boss1_x = arm_l - hinge_od;
    boss_y = -3/4*arm_h;
    boss_h = 2;
    boss_d = 5;

    module bolt_hole() {
        // Using M4 screws
        M4_pitch = 0.7;
        M4_free_d = 4.5;
        M4_close_d = 4.3;
        M4_head_h = 3.1;
        M4_head_d = 8.0;
        M4_nut_w = 7.0;
        M4_nut_d = M4_nut_w / cos(180 / 6);  // 6 = hex nut
        M4_nut_h = 3.2;
        
        M3_pitch = 0.5;
        M3_free_d = 3.4;
        M3_close_d = 3.4;
        M3_head_h = 1.65;  // BOGUS!!!
        M3_head_d = 5.6;
        M3_nut_w = 5.5;
        M3_nut_d = M3_nut_w / cos(180 / 6);  // 6 = hex nut
        M3_nut_h = 2.4;

        $fn = 0;
        $fs = nozzle_d/2;

        cylinder(h=arm_th+0.1, d=M3_free_d+nozzle_d, center=true);
        // recess for the head (on the bottom!)
        translate([0, 0, -arm_th/2-0.1])
            cylinder(h=M3_head_h+0.1, d=M3_head_d);
        // recess for the nut (on the top!)
        nut_h = M3_nut_h + 1.5*M3_pitch;
        translate([0, 0, arm_th/2-nut_h])
            cylinder(h=nut_h+0.1, d=M3_nut_d, $fn=6);

        echo(str("Bolt should be M3P0.5 x ", arm_th - M3_head_h, " mm"));
    }

    module hinge_bolt_hole() {
         bolt_hole();
    }

    module slate_bolt_holes() {
        bolt_spread = (arm_l - hinge_od);
        bolts = max(2, min(1 + floor(bolt_spread/50), 5));
        dx = bolt_spread / (bolts - 1);
        translate([0, -5/4*arm_h, 0]) {
            for (i = [0:bolts-1]) {
                translate([i*dx, 0, 0]) bolt_hole();
            }
        }
    }

    module bearing_608() {
        linear_extrude(bearing_w, convexity=10, center=true) {
            difference() {
                circle(d=bearing_od);
                circle(d=bearing_id);
            }
        }
    }

    module top_arm() {
        linear_extrude(bearing_w, convexity=10, center=true) {
            difference() {
                hull() {
                    circle(d=hinge_od-nozzle_d);
                    translate([hinge_od/2, 0, 0])
                        square(arm_h, center=true);
                }
                circle(d=bearing_od);  // intentionally tight fit
            }
        }
        linear_extrude(arm_th, center=true) {
            hull() {
                translate([hinge_od+nozzle_d, 0, 0]) square(arm_h, center=true);
                translate([arm_l-arm_h, 0, 0]) square(arm_h, center=true);
            }
        }
    }
    
    module bottom_half_stick() {
        pin_d = bearing_id - nozzle_d;
        difference() {
            linear_extrude(arm_th/2, center=false) {
                circle(d=pin_d);
                translate([0, -arm_h, 0]) {
                    hull() {
                        square(arm_h, center=true);
                        translate([arm_l-arm_h, 0, 0])
                            square(arm_h, center=true);
                    }
                }
            }

            translate([-hinge_od/2-0.1, -(slate_h+arm_h/2) - arm_h, 0]) {
                linear_extrude(slate_th + nozzle_d/2, center=true) {
                    square([slate_w+0.2, slate_h+arm_h/2]);
                }
            }
        }

        translate([0, 0, (bearing_w + nozzle_d)/2]) {
            linear_extrude((arm_th - bearing_w - nozzle_d)/2, center=false) {
                hull() {
                    circle(d=hinge_od);
                    translate([0, -arm_h, 0]) square(arm_h, center=true);
                }
            }
        }
    }

    module front_arm() {
        difference() {
            union() {
                bottom_half_stick();
                translate([boss0_x, boss_y, -boss_h])
                    cylinder(h=boss_h+0.1, d=boss_d);
            }
            translate([boss1_x, boss_y, -0.1]) {
                cylinder(h=boss_h+nozzle_d, d=boss_d+nozzle_d);
            }
            
            hinge_bolt_hole();
            slate_bolt_holes();
        }
    }

    module back_arm() {
        difference() {
            union() {
                rotate([0, 180, 0]) mirror([1, 0, 0])
                    bottom_half_stick();
                translate([boss1_x, boss_y, -0.1])
                    cylinder(h=boss_h, d=boss_d);
            }
            translate([boss0_x, boss_y, -boss_h]) {
                cylinder(h=boss_h+nozzle_d, d=boss_d+nozzle_d);
            }
            hinge_bolt_hole();
            slate_bolt_holes();
        }
    }

    if ($preview) {
        if (use_608_bearing) color("silver") bearing_608();
        color("orange") rotate([0, 0, 15]) top_arm();
        color("DodgerBlue") front_arm();
        color("green") back_arm();
        #translate([-hinge_od, -arm_h/2, 0]) bolt_hole();
    } else {
        translate([0, 0, arm_h/2]) rotate([90, 0, 0]) top_arm();
        translate([0, -(3/2*arm_h+arm_th/2+5), arm_th/2]) rotate([180, 0, 0]) front_arm();
        translate([0, (3/2*arm_h+arm_th/2+5), arm_th/2]) back_arm();
    }
}

clapper_slate(w=60, th=1/8*25.4, $fn=60);
