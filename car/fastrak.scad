// Bracket to hold FasTrak Flex transponder to windshield with suction cup.
// Adrian McCarthy 2023-06-20

module foldup_etag_bracket(th=2, layer_h=0.2, nozzle_d=0.4) {
    etag_l = 110;
    etag_w = 36 + nozzle_d;
    etag_h = 15 + nozzle_d;
    
    suction_od = 30;
    suction_id = 6.5;
    suction_key = 10.5;

    keyhole_h = 3/2*suction_id + 1/2*suction_key;
    tab_d = 4*th + keyhole_h;
    bracket_l = etag_l/4;

    face = etag_w + 2*th;
    side = etag_h + 2*th;
    box_h = th + etag_w + 2*th + etag_h + 2*th + etag_w + 2*th + etag_h + th;

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
                    translate([0, tab_d/2]) circle(d=tab_d);
                    translate([0, -box_h/2])
                        square([bracket_l, box_h], center=true);
                }
                translate([0, -(box_h+th/2)])
                    square([tab_d/3, th], center=true);
            }
            translate([0, keyhole_h]) {
                hull() {
                    circle(d=suction_id+nozzle_d);
                    translate([0, -suction_id]) circle(d=suction_id+nozzle_d);
                }
                translate([0, -suction_id]) circle(d=suction_key+nozzle_d);
            }
            translate([0, -(th+nozzle_d)/2])
                square([tab_d/3+nozzle_d, th+nozzle_d], center=true);
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
            groove(bracket_l+0.1);
            translate([0, -(th+etag_h+th), 0]) {
                groove(bracket_l+0.1);
                translate([0, -(th+etag_w+th), 0]) {
                    groove(bracket_l+0.1);
                }
            }
        }
    }
}

foldup_etag_bracket(layer_h=0.3);
