// Rails for parts rack
// Adrian McCarthy 2023-04-22
//
// For the rebuild of my parts organizer, using 2020 aluminum extrusion.
// Rails do not need screws.  They simply stack by sliding the vertical
// spacers into the T_slots
//
// Sized for the (now discontinued) Husky 11-inch small parts organizers.
//
// Note:  The rails are printed upsidedown.
//
// Note:  The underside of the backstop indicates which side the rail is
// for ("L" for left, "R" for right), and the height of the spacer in mm.
//
// Note:  The rails support the boxes by the lips just below the lids.
//
// Recommend printing in Prusament PETG with the 0.3mm layers (like draft
// mode), but with a minimum of 3 perimenters for strength.  Good adhesion
// on the first layer is important.

//
// For a rack height of 800 mm minus 40 mm for top and bottom rails, the
// first rail_spacing should be 34, and the rest should be 50.6, which
// yields 15 boxes with gaps above and below.

module rack_rails(rail_spacing=50.6, nozzle_d=0.4) {
    box_w = 262; // at the hanging point
    shelf_w = 300;

    th=3;
    rail_w = (shelf_w - box_w) / 2;
    rail_l = 190;
    rail_h = 2*th;

    rail_profile = [
      [0, 0],
      [0, -rail_h],
      [th, -rail_h],
      [rail_w, -th],
      [rail_w, 0]
    ];

    backstop_w = 20;
    backstop_l = 15;
    backstop_h = rail_h;
    backstop_r = 5;
    
    label_x = (rail_w+backstop_w+th)/2;
    label_y = (rail_l-backstop_l)/2;
    label_z = backstop_h;
    
    easement_r = rail_w/2;

    a = (6-nozzle_d)/2;
    b = 16.4/2;
    c = (10-nozzle_d)/2;
    d = 14/2;
    t_profile = [
        [ 10+nozzle_d,   a],
        [  b,   a],
        [  b,   c],
        [  d,   c],
        [  d,  -c],
        [  b,  -c],
        [  b,  -a],
        [ 10+nozzle_d, -a],
        [ 10+nozzle_d, -5],
        [ 10+th,       -5],
        [ 10+th,        5],
        [ 10+nozzle_d,  5]
    ];

    module raw_rail() {
        intersection() {
            rotate([90, 0, 0]) {
                linear_extrude(rail_l, convexity=8, center=true) {
                    polygon(rail_profile);
                }
            }
            translate([0, 0, -rail_h]) {
                linear_extrude(rail_h+0.1, convexity=8) {
                    hull() {
                        translate([0, -rail_l/2]) {
                            square([0.1, rail_l]);
                            translate([rail_w-easement_r, easement_r])
                                circle(r=easement_r, $fs=nozzle_d/2);
                        }
                        translate([0, rail_l/2-0.1])
                            square([rail_w, 0.1]);
                    }
                }
            }
        }

        translate([-(10+nozzle_d), 0, -rail_spacing]) {
            translate([0, 150/2+10, 0]) {
                linear_extrude(rail_spacing, convexity=10) {
                    polygon(t_profile);
                }
            }

            translate([0, -(150/2+10), 0]) {
                linear_extrude(rail_spacing, convexity=10) {
                    polygon(t_profile);
                }
            }
        }
        
        translate([0, rail_l/2, -backstop_h]) {
            linear_extrude(backstop_h, convexity=8) {
                translate([0, -(backstop_l+backstop_r)]) {
                    difference() {
                        square([rail_w+backstop_w, backstop_l+backstop_r]);
                        translate([rail_w+backstop_r, 0]) {
                            circle(r=backstop_r, $fs=nozzle_d/2);
                            square([backstop_w, backstop_r]);
                        }
                    }
                }
            }
        }
    }

    module left_rail() {
        rotate([0, 180, 0]) raw_rail();
        translate([-label_x, label_y, label_z]) {
            linear_extrude(1, center=true, convexity=10) {
                text(str("L ", rail_spacing), size=8, halign="center", valign="center");
            }
        }
    }

    module right_rail() {
        rotate([0, 180, 0]) mirror([1, 0, 0]) raw_rail();
        translate([label_x, label_y, label_z]) {
            linear_extrude(1, center=true, convexity=10) {
                text(str("R ", rail_spacing), size=8, halign="center", valign="center");
            }
        }
    }

    // We pack the rails tightly so that we can get several pairs on
    // the build plate.
    dx = rail_w + 1;
    ddx = 50;
    dy = backstop_l/2 + 1;
    for (i = [0:1]) {
        translate([(2*i+0.5)*ddx, 0, 0]) {
            translate([ dx,  dy, 0]) left_rail();
            translate([-dx, -dy, 0]) rotate([0, 0, 180]) left_rail();
            translate([ddx - dx,  dy, 0]) right_rail();
            translate([ddx + dx, -dy, 0]) rotate([0, 0, 180]) right_rail();
        }
    }
}

//rack_rails(rail_spacing=34);  // 34 for bottom rails
rack_rails();
