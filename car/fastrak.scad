// Bracket to hold FasTrak Flex transponder to windshield with suction cup.
// Adrian McCarthy 2023-06-20

module foldup_etag_bracket(th=2, layer_h=0.2, nozzle_d=0.4) {
    etag_l = 110;
    etag_w = 36;
    etag_h = 15;
    
    suction_od = 30;
    suction_id = 6.5;
    suction_key = 10.5;

    keyhole_h = 3/2*suction_id + 1/2*suction_key;
    hanger_d = 4*th + keyhole_h;
    bracket_w = etag_l/2;

    box_h = th + etag_w + 2*th + etag_h + 2*th + etag_w + 2*th + etag_h;
    tab_w = hanger_d/3;
    tab_h = th;
    tab_l = 2*th;
    slot_w = tab_w + nozzle_d/2;
    slot_h = tab_h + nozzle_d/2;

    $fs = nozzle_d/2;
    
    module profile() {

        module cutout() {
            ellipse_major = etag_w-2*th;
            ellipse_minor = 24;  // based on logo and switch placement
            translate([0, -etag_w/2])
                scale([1, ellipse_major/ellipse_minor])
                    circle(d=ellipse_minor);
        }

        difference() {
            union() {
                hull() {
                    translate([0, hanger_d/2]) circle(d=hanger_d);
                    translate([0, -box_h/2])
                        square([bracket_w, box_h], center=true);
                }
                translate([0, -(box_h+tab_l/2)])
                    square([tab_w, tab_l], center=true);
            }
            translate([0, keyhole_h]) {
                hull() {
                    circle(d=suction_id+nozzle_d);
                    translate([0, -suction_id]) circle(d=suction_id+nozzle_d);
                }
                translate([0, -suction_id]) circle(d=suction_key+nozzle_d);
            }
            translate([0, -slot_h/2])
                square([slot_w, slot_h], center=true);
            translate([0, -th]) {
                cutout();
                translate([0, -(etag_w+2*th+etag_h+2*th)]) {
                    cutout();
                }
            }
        }
    }
    
    module groove(w) {
        rotate([90, 0, 90]) {
            linear_extrude(w, center=true) {
                polygon([
                    [layer_h/2, layer_h],
                    [layer_h/2 + th, layer_h+th],
                    [-(layer_h/2 + th), layer_h+th],
                    [-(layer_h/2), layer_h]
                ]);
            }
        }
    }
    
    difference() {
        linear_extrude(th, convexity=8) profile();
        translate([0, -(th+etag_w+th), 0]) {
            groove(bracket_w+0.1);
            translate([0, -(th+etag_h+th), 0]) {
                groove(bracket_w+0.1);
                translate([0, -(th+etag_w+th), 0]) {
                    groove(bracket_w+0.1);
                }
            }
        }
    }
}

foldup_etag_bracket(layer_h=0.3);
