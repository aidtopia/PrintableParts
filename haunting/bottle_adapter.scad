// For the never-ending floating bottle illusion
// Adrian McCarthy 2023-06-26
//
// Based on a Make & Take by Eric Van Huystee (URL HERE!!!)
//
// Patterned after a project by Wicked Makers https://youtu.be/3IJSDtKw0KM
//
// Another version of the adapter, for a slightly different bottle, was
// designed by Vince Parsons.
//
// The idea is to attach the rigid, clear input tube to the inside of the
// neck of the bottle while allowing the liquid to flow back out all the
// way around the tube.  The original design used a bit of flexible tubing
// attached to the inside of the neck, but that didn't reliably let the
// output fluid flow to the "underside" of the bent tube, spoiling the
// illusion.

module bottle_adapter() {
    bottle_od = 25;
    bottle_id = 21.5;
    tube_od = 12;
    tube_id = 8;
    spokes = 10;
    spoke_th = 1.2;
    ring_th = min(1.2, (tube_od - tube_id) / 2);
    ring_od = tube_od + 2*ring_th;
    adapter_l = 20;
    nozzle_d = 0.4;
    twist = 15;
    tilt = 10;
    bias = min(2, (bottle_id-ring_od)/2 * sin(tilt));

    $fs=nozzle_d/2;
    
    module spokes(od) {
        intersection() {
            circle(d=od);

            dtheta = 360 / spokes;
            for (theta = [dtheta:dtheta:360]) {
                rotate([0, 0, theta])
                    translate([0, -spoke_th/2])
                        square([od, spoke_th]);
            }
        }
    }
    
    module core() {
        translate([0, -bias, 0]) circle(d=ring_od);
    }
    
    difference() {
        intersection() {
            union() {
                translate([0, 0, -adapter_l/2]) {
                    linear_extrude(adapter_l, convexity=10, twist=twist) {
                        spokes(bottle_id);
                    }
                    linear_extrude(nozzle_d, convexity=10, twist=twist*nozzle_d/adapter_l) {
                        spokes(bottle_od);
                    }
                }
                rotate([-tilt, 0, 0]) {
                    linear_extrude(2*adapter_l, convexity=4,center=true) {
                        core();
                    }
                }
            }
            cube([2*bottle_od, 2*bottle_od, adapter_l], center=true);
        }
        rotate([-tilt, 0, 0]) translate([0, -bias, 0])
            cylinder(d=tube_od + nozzle_d, h=2*adapter_l, center=true);
    }

    tube_ir = tube_id/2;
    input_area = PI * tube_ir*tube_ir;

    bottle_ir = bottle_id/2;
    bottle_area = PI * bottle_ir*bottle_ir;
    ring_or = ring_od/2;
    ring_area = PI * ring_or*ring_or;
    spoke_area = (bottle_ir - ring_or) * spoke_th; // approximate
    spokes_area = spokes * spoke_area;
    output_area = bottle_area - ring_area - spokes_area;

    echo(str("Cross sectional area of input tube:   ", input_area, " mm^2"));
    echo(str("Total cross sectional area of output: ", output_area, " mm^2"));
    assert(output_area >= input_area);
}

bottle_adapter();
