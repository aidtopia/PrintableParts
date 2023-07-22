// Bracket to hold FasTrak Flex transponder to windshield with suction cup.
// Adrian McCarthy 2023-06-20

module foldup_etag_bracket(th=2, layer_h=0.2, nozzle_d=0.4) {
    etag_l = 110;
    etag_w = 36;
    etag_h = 15;
    
    suction_od = 30;
    suction_id = 6.5;
    suction_key = 10.5;

    keyhole_h1 = 3/2*suction_id + 1/2*suction_key;
    keyhole_h2 = keyhole_h1 - (suction_id + suction_key)/2;
    hanger_d = 4*th + keyhole_h1;
    bracket_w = etag_l/2;

    box_h = th + etag_w + 2*th + etag_h + 2*th + etag_w + 2*th + etag_h;
    tab_w = hanger_d/2;
    tab_h = th;
    tab_l = 2*th;
    slot_w = tab_w + nozzle_d;
    slot_h = tab_h + nozzle_d;
    slot_dx = bracket_w/4;

    $fs = nozzle_d/2;
    
    module profile() {

        module cutout() {
            ellipse_major = etag_w-3*th;
            ellipse_minor = min(ellipse_major, bracket_w-2*th);
            translate([0, -etag_w/2])
                scale([1, ellipse_major/ellipse_minor])
                    circle(d=ellipse_minor);
        }
        
        module tab() {
            depth = tab_h + nozzle_d;
            stem = 4*nozzle_d;
            overhang = 3*nozzle_d;
            clip_profile = [
                [0, 0],
                [0, -depth],
                [overhang, -depth],
                [-nozzle_d, -depth-overhang],
                [-stem, -depth-overhang],
                [-stem, 0]
            ];
            translate([ tab_w/2, 0]) polygon(clip_profile);
            translate([-tab_w/2, 0]) mirror([1, 0, 0]) polygon(clip_profile);
            translate([0, -depth/2]) hull() {
                square([tab_w/2, depth+overhang], center=true);
                translate([0, -depth/4]) circle(d=tab_w/2);
            }
        }
        
        module slot() {
            translate([0, -slot_h/2])
                square([slot_w, slot_h], center=true);
        }

        difference() {
            union() {
                hull() {
                    translate([0, hanger_d/2]) circle(d=hanger_d);
                    translate([0, -box_h/2])
                        square([bracket_w, box_h], center=true);
                }
                translate([0, -box_h]) {
                    translate([-slot_dx, 0]) tab();
                    translate([ slot_dx, 0]) tab();
                }
            }
            union() {
                translate([0, keyhole_h1]) hull() {
                    circle(d=suction_id+nozzle_d);
                    translate([0, -suction_id]) circle(d=suction_id+nozzle_d);
                }
                translate([0, keyhole_h2]) circle(d=suction_key+nozzle_d);
            }
            translate([-slot_dx, 0]) slot();
            translate([ slot_dx, 0]) slot();
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

    module brace() {
        translate([-th, 0]) square([2*th, hanger_d]);
    }
    
    module label() {
        label = "FASTRAK FLEX";
        typeface = "Liberation Sans:style=Bold";
        label_w = 10.2; // At size=1, the text is approximately 10 mm wide.
        type_size = (bracket_w-th)/label_w;
            text(label, font=typeface, size=type_size,
                 halign="center", valign="center");
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
    
    difference() {
        linear_extrude(3*th, convexity=4) {
            intersection() {
                translate([-bracket_w/2, 0]) square([bracket_w, hanger_d]);
                profile();
            }
        }
        translate([0, 0, th]) {
            linear_extrude(3*th) {
                hull() {
                    translate([0, keyhole_h1]) circle(d=suction_key+nozzle_d);
                    translate([0, keyhole_h2]) circle(d=suction_key+nozzle_d);
                }
            }
        }
    }

    translate([0, -th, th-0.1]) {
        linear_extrude(3*layer_h, convexity=10) {
            translate([0, -(etag_w+2*th+etag_h/2)]) {
                label();
                translate([0, -(etag_h/2+2*th+etag_w+2*th+etag_h/2)]) {
                    label();
                }
            }
        }
    }
}

foldup_etag_bracket(layer_h=0.3);
