// Crystal Icicle Ornament Storage Boxes
// Adrian McCarthy 2025-01-01

// The crystal icicle ornaments for the Christmas tree come in two sizes.
// The diameters are rounded up a bit to account for variation.  There's
// also a clearance parameter to keep the holes from being too tight.
small_d1 = 4.0;
small_d2 = 7.5;
small_h = 90;

large_d1 = 4.5;
large_d2 = 8.5;
large_h = 140;

module icicle_box(rows, cols, h, d1, d2, th=1.6, clearance=1.0) {
    // Relief gives extra space between the holes and the walls of the box.
    relief = clearance;
    // dx and dy are the spacing from hole to hole
    dx = d2 + clearance + th;
    dy = d2 + clearance + th;
    // The grid contains the regularly spaced holes.
    grid_w = cols*dx;
    grid_l = rows*dy;
    
    box_h = h + 2*th + d1/2 + th;
    recess = 16 + th;
    
    grid_h = box_h - recess;

    module grid_footprint() {
        offset(delta=relief) square([grid_w, grid_l]);
    }
    
    module shell_footprint() {
        offset(r=2*th) offset(r=-th) grid_footprint();
    }
    
    module cap_footprint() {
        offset(delta=th + clearance/4) shell_footprint();
    }
    
    module icicle_hole() {
        hull() {
            sphere(d=d1 + clearance);
            translate([0, 0, h - (d1 + d2)/2]) sphere(d=d2 + clearance);
        }
    }

    // A grid of holes for the icicles.
    module grid() {
        difference() {
            linear_extrude(grid_h, convexity=10) {
                grid_footprint();
            }

            translate([0, 0, th+d1/2]) {
                for (row=[1:rows]) {
                    translate([0, (row-0.5)*dy, 0]) {
                        for (col=[1:cols]) {
                            translate([(col-0.5)*dx, 0]) {
                                icicle_hole();
                            }
                        }
                    }
                }
            }
        }
    }
    
    // A shell to make it a box.
    module shell() {
        linear_extrude(box_h, convexity=10) {
            difference() {
                shell_footprint();
                offset(delta=-th) shell_footprint();
            }
        }
    }

    module box() {
        grid();
        shell();
    }

    // A cap for the box.
    module cap() {
        linear_extrude(recess) {
            difference() {
                cap_footprint();
                offset(delta=-th) cap_footprint();
            }
        }
        translate([0, 0, recess - th]) {
            linear_extrude(th) cap_footprint();
        }
    }

    box();

    translate([0, -(4*th + 3*clearance), 0])
    rotate([180, 0, 0])
    translate([0, 0, -recess]) {
        cap();
    }
}

icicle_box(rows=4, cols=5, h=small_h, d1=small_d1, d2=small_d2, $fs=0.2);
//icicle_box(rows=5, cols=5, h=large_h, d1=large_d1, d2=large_d2, $fs=0.2);
