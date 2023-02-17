// Clapper Slate for video production
// Adrian McCarthy 2023-02-17

module clapper_slate(w=60, h=0, th=25.4/4, use_608_bearing=false, nozzle_d=0.4) {
    slate_w = w;
    slate_h = (h > 0) ? h : 3/4 * slate_w;
    slate_th = th;

    bearing_id = use_608_bearing ?  8 : 8;
    bearing_w  = use_608_bearing ?  7 : 7;
    bearing_od = use_608_bearing ? 22 : bearing_id;

    hinge_od = 26;  // = od of 608 bearing + 4;

    stick_l = slate_w;
    stick_h = hinge_od;
    stick_th = max(21.65, 3*bearing_w);

    tab_l = 0.75*hinge_od;
    tab_h = 0.75*stick_h;
    tab_th = bearing_w;

    boss0_x = 0;
    boss1_x = stick_l - hinge_od;
    boss_y = -3/4*stick_h;
    boss_h = 2;
    boss_d = 5;

    // The bolts are arranged to drill from back (-Z) to front (+Z)
    // because the front side will likely be covered with a focus and
    // color reference.  That cover will hide and retain the recessed
    // hex nuts rather than covering the bolt heads, preventing
    // disassembly.
    module bolt_hole() {
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

        cylinder(h=stick_th+0.1, d=M3_free_d+nozzle_d, center=true);
        // recess for the head (on the bottom!)
        translate([0, 0, -stick_th/2-0.1])
            cylinder(h=M3_head_h+0.1, d=M3_head_d);
        // recess for the nut (on the top!)
        nut_h = M3_nut_h + 1.5*M3_pitch;
        translate([0, 0, stick_th/2-nut_h])
            cylinder(h=nut_h+0.1, d=M3_nut_d, $fn=6);

        echo(str("Bolt should be M3P0.5 x ", stick_th - M3_head_h, " mm"));
    }

    module bearing_bolt_hole() {
         translate([hinge_od, 0, 0]) rotate([0, 0, 90]) bolt_hole();
    }

    module hinge_bolt_hole() {
         bolt_hole();
    }

    module slate_bolt_holes() {
        bolt_spread = (stick_l - hinge_od);
        bolts = max(2, min(1 + floor(bolt_spread/50), 5));
        dx = bolt_spread / (bolts - 1);
        translate([0, -5/4*stick_h, 0]) {
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
    
    module bearing_tab(clearance=0) {
        dx = (tab_th + clearance)/2;
        dy = dx;
        right = 0 + dx;
        left = -right;
        top = (tab_h + clearance)/2;
        bottom = -top;
        translate([hinge_od/2-0.1, 0]) {
            rotate([0, 90, 0]) {
                linear_extrude(tab_l+0.1+clearance, convexity=10) {
                    polygon([
                        [0, top],
                        [right, top-dy],
                        [right, bottom+dy],
                        [0, bottom],
                        [left, bottom+dy],
                        [left, top-dy],
                    ]);
                }
            }
        }
    }

    module bearing_block() {
        // If we're using a bearing, we want a tight fit.
        // Otherwise, we increase the clearance to allow rotation.
        clearance = use_608_bearing ? 0 : nozzle_d;
        linear_extrude(bearing_w, convexity=10, center=true) {
            difference() {
                hull() {
                    circle(d=hinge_od-nozzle_d);
                    translate([0, -hinge_od/2])
                        square([hinge_od/2+nozzle_d, stick_h]);
                }
                circle(d=bearing_od + clearance);
            }
        }
        difference() {
            bearing_tab();
            bearing_bolt_hole();
        }
    }

    module top_stick() {
        difference() {
            linear_extrude(stick_th, center=true) {
                hull() {
                    translate([hinge_od+nozzle_d, 0])
                        square(stick_h, center=true);
                    translate([stick_l-stick_h, 0])
                        square(stick_h, center=true);
                }
            }
            bearing_tab(clearance=nozzle_d);
            bearing_bolt_hole();
        }
    }
    
    module lower_half_stick() {
        pin_d = bearing_id - nozzle_d;
        difference() {
            linear_extrude(stick_th/2, center=false) {
                circle(d=pin_d);
                translate([0, -stick_h, 0]) {
                    hull() {
                        square(stick_h, center=true);
                        translate([stick_l-stick_h, 0])
                            square(stick_h, center=true);
                    }
                }
            }

            translate([-hinge_od/2-0.1, -(slate_h+stick_h/2)-stick_h, 0]) {
                linear_extrude(slate_th + nozzle_d/2, center=true) {
                    square([slate_w+0.2, slate_h+stick_h/2]);
                }
            }
        }

        translate([0, 0, (bearing_w + nozzle_d)/2]) {
            linear_extrude((stick_th - bearing_w - nozzle_d)/2, center=false) {
                hull() {
                    circle(d=hinge_od);
                    translate([0, -stick_h])
                        square(stick_h, center=true);
                }
            }
        }
    }

    module front_of_lower_stick() {
        difference() {
            union() {
                lower_half_stick();
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

    module back_of_lower_stick() {
        difference() {
            union() {
                mirror([0, 0, 1]) lower_half_stick();
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
        // Parts are shown in their design orientation, which
        // matches how they will go together.
        if (use_608_bearing) color("silver") bearing_608();
        rotate([0, 0, 15])  {
            color("yellow")     bearing_block();
            color("orange")     top_stick();
        }
        color("DodgerBlue")     front_of_lower_stick();
        color("LimeGreen")      back_of_lower_stick();
        #translate([-hinge_od, -stick_h/2, 0]) bolt_hole();
    } else {
        // Orient parts for printing.
        translate([0, 0, stick_h/2]) rotate([90, 0, 0])
            top_stick();
        translate([-hinge_od, 0, bearing_w/2]) bearing_block();
        translate([0, -(3/2*stick_h+stick_th/2+5), stick_th/2])
            rotate([180, 0, 0])
                front_of_lower_stick();
        translate([0, (3/2*stick_h+stick_th/2+5), stick_th/2])
            back_of_lower_stick();
    }
}

clapper_slate(w=60, th=1/8*25.4, $fn=60);
