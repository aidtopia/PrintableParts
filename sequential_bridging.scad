// Experimenting with "sequential bridging", which is Makers Muse's term
// for the Prusa trick for making unsupported holes.

// Cross section:
//
//  *******   *******
//  *******   *******
//  *******   *******
//  *******   *******  <--- unsupported ledge
//  ****         ****
//  ****         ****
//
// When printing, where the hole transitions from a wider to a narrower
// diameter, the ledge is unsupported.  With small holes, this may be
// good enough, but with larger ones, the ledge will droop and the
// wider recess won't be very clean.
//
// The sequential bridging trick is to create two pairs of bridges on
// two consecutive layers that can then support the actual ledge.

nozzle_d = 0.4;
layer_h = 0.3;
$fs = nozzle_d/2;

bore_d = 3.4;
recess_d = 6;
recess_h = 2.4;

module sequential_bridges(layers=2, layer_h=0.3) {
    module bridge(h) {
        translate([0, 0, -h]) {
            linear_extrude(h+0.0001) {
                difference() {
                    circle(d=recess_d+nozzle_d+0.0001);
                    square([bore_d+nozzle_d, recess_d+nozzle_d+0.0001],
                           center=true);
                }
            }
        }
    }

    for (layer = [1:layers]) {
        theta = layer * 180/layers;
        rotate([0, 0, theta]) bridge(layer*layer_h);
    }
}

module floating_hole(bridging_layers=2) {
    ledge_h = bridging_layers * layer_h;
    
    difference() {
        linear_extrude(5, convexity=8) {
            difference() {
                circle(d=20);
                circle(d=bore_d+nozzle_d);
            }
        }

        translate([0, 0, -1]) {
            linear_extrude(1 + recess_h + ledge_h, convexity=8) {
                circle(d=recess_d+nozzle_d);
            }
        }
    }
    
    translate([0, 0, recess_h + ledge_h])
        sequential_bridges(bridging_layers, layer_h);
}

floating_hole(bridging_layers=2);
