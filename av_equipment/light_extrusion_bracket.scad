// Bracket to connect A/V equipment (like a light) to 2020 extrusion
// Adrian McCarthy 21-09-2023

function thou(x) = 25.5 * x/1000;

module av_bracket(th=5, nozzle_d=0.4) {
    extrusion_size = 20;
    washer_d = 26;
    washer_recess = 2;
    reach = 50;
    bracket_l = th + reach + extrusion_size + th;
    bracket_w = th + extrusion_size + th;
    bracket_h = max(extrusion_size, washer_d) + th;
    $fs = nozzle_d/2;

    translate([0, 0, bracket_h/2]) rotate([-90, 0, 0]) {
        difference() {
            translate([0, 0, th]) rotate([90, 0, 0]) {
                linear_extrude(bracket_h, convexity=10, center=true) {
                    translate([-th, -th]) {
                        square([bracket_l, th]);
                        square([th, bracket_w]);
                    }
                    translate([-th, extrusion_size+nozzle_d/2]) {
                        square([th + extrusion_size, th - nozzle_d/2]);
                    }
    //                translate([extrusion_size-nozzle_d, 0]) {
    //                    square([nozzle_d, extrusion_size+nozzle_d/2]);
    //                }
                }
            }
            
            
            translate([extrusion_size + reach - washer_d/2, 0, -0.1]) {
                translate([0, 0, th-washer_recess]) {
                    linear_extrude(th) {
                        circle(d=washer_d+nozzle_d);
                    }
                }
                linear_extrude(th) {
                    circle(d=thou(266)+nozzle_d);
                }
            }
            translate([extrusion_size/2, 0, -0.1]) {
                linear_extrude(bracket_w+2) {
                    circle(d=5.5+nozzle_d);
                }
            }
        }
    }
}

av_bracket();
