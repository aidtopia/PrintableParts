// Drill press crank extension
// Adrian McCarthy 2023-09-17

// The nice table my brother made for my 10" Craftsman Drill Press
// blocks the crank used to raise and lower the table.  This is a shaft
// extension to move the crank out.  Printed parts have limited strength
// and the size creates quite a bit of leverage.  So I'll be printing
// these in PETG with extra perimeters and more infill.  The pieces nest
// which reinforces both of them.  Finally, I've sized the coupler to
// just fit inside a sleeve of 3/4" schedule 40 PVC pipe, figuring I
// could expoxy the coupler inside some pipe for additional rigidity.

function inch(inches) = inches * 25.4;

module crank_extension(nozzle_d=0.4) {
    $fs = nozzle_d/2;

    shaft_d = inch(0.550);
    shaft_flat_offset = shaft_d - inch(0.480);
    shaft_l = inch(7/8);  // length of existing shaft
    crank_offset = inch(2.5);  // final may be inch(6.5)

    pvc_inner_d = inch(0.804);  //  average for 3/4" schedule 40 PVC pipe

    // The existing shaft has a flattened side for a set screw.
    // We'll use that as a key.
    module shaft_profile() {
        intersection() {
            circle(d=shaft_d);
            translate([-shaft_flat_offset, 0])
                square(shaft_d, center=true);
        }
    }

    module coupler() {
        linear_extrude(shaft_l + crank_offset) {
            difference() {
                circle(d=pvc_inner_d-nozzle_d/2);
                offset(r=nozzle_d/2) shaft_profile();
            }
        }
    }

    module shaft_extension() {
        linear_extrude(crank_offset + shaft_l) {
            shaft_profile();
        }
        // The crank connection is a cylindrical hole about the same
        // length as the original shaft.  The set screw is halfway
        // down that length, so the key shape need not extend the
        // entire length of the extension.  We'll give it a round
        // base for better bed adhesion.
        linear_extrude(shaft_l/3) circle(d=shaft_d);
    }

    coupler();
    translate([inch(1), 0]) shaft_extension();
}

crank_extension();
