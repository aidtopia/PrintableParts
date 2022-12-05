// Pressure regulator bracket
// Adrian McCarthy 2022


module pressure_regulator_bracket(nozzle_d=0.4) {
    id = 29.5 + nozzle_d;
    od = 36;
    th = 2.4;
    apron = 20; // from back of regulator knob to mounting plate

    module top() {
        linear_extrude(th, convexity=4) {
            difference() {
                hull() {
                    translate([-od/2, id/2])
                        square([od, apron]);
                    circle(d=od, $fs=nozzle_d/2);
                }
                circle(d=id, $fs=nozzle_d/2);
            }
        }

        // Custom supports right where we need them
        translate([-od/2, 0, 0]) {
            for (i = [-3:3]) {
                theta = 5*i;
                    rotate([0, 0, theta])
                        translate([0, -nozzle_d/4, nozzle_d/2])
                            cube([id+(od-id)/2, nozzle_d/2, th-nozzle_d]);
            }
        }
    }


    module back() {
        brace = apron;
        open_r = (2*brace - th) / 2;
        bottom = -40;

        // 35mm DIN rail dimensions
        din_notch_size = 5 + nozzle_d;
        din_notch_depth = 4;
        din_rail_th = 1 + nozzle_d;
        din_hook_depth = din_notch_depth - din_rail_th;

        lower = bottom + 1;
        upper = lower + 35 + nozzle_d;

        linear_extrude(od, convexity=4) {
            difference() {
                polygon([
                    [0, 0],
                    [-brace, 0],
                    [-brace, -th],
                    [-th, -brace],
                    [-2*th, bottom + 2*th],
                    [-2*th, bottom + nozzle_d],
                    [-2*th + nozzle_d, bottom],                    
                    [th, bottom],
                    [th, lower],
                    [th - din_hook_depth, lower + 1],
                    [th - din_hook_depth, lower],
                    [th - din_notch_depth, lower],
                    [1.2-2*th, lower + nozzle_d],
                    [1.2-2*th, lower + 2.4],
                    [1.2-2*th + nozzle_d, lower + 2*nozzle_d],
                    [th - din_notch_depth, lower + nozzle_d],
                    [th - din_notch_depth, lower + din_notch_size],
                    [th, lower + din_notch_size + nozzle_d],
                    [th, upper - din_notch_size - 3],
                    [th - din_notch_depth, upper - din_notch_size],
                    [th - din_notch_depth, upper],
                    [th - din_hook_depth, upper],
                    [th - 1, upper - 2],
                    [th, upper - 2],

                    [th, -th]
                ]);
                translate([-(th + open_r), -(th + open_r)])
                    circle(r=open_r, $fs=nozzle_d/2);
            }
        }
    }
    
    rotate([-90, 0, 0])
        translate([-(id/2 + apron), -od/2, -th])
            rotate([0, 0, -90])
                top();

    back();
}

pressure_regulator_bracket();
