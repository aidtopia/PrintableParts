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
    tab_w = hanger_d/2;
    tab_h = th;
    tab_l = 2*th;
    slot_w = tab_w + nozzle_d/2;
    slot_h = tab_h + nozzle_d/2;
    slot_dx = bracket_w/4;

    $fs = nozzle_d/2;
    
    module profile() {

        module cutout() {
            ellipse_major = etag_w-2*th;
            ellipse_minor = min(ellipse_major, bracket_w-2*th);
            translate([0, -etag_w/2])
                scale([1, ellipse_major/ellipse_minor])
                    circle(d=ellipse_minor);
        }
        
        module tab() {
            //square([tab_w, tab_l], center=true);
            depth = -(tab_h + nozzle_d/2);
            stem = 3*nozzle_d;
            overhang = 3*nozzle_d;
            clip_profile = [
                [0, 0],
                [0, depth],
                [overhang, depth],
                [-nozzle_d, depth-overhang],
                [-stem, depth-overhang],
                [-stem, 0]
            ];
            translate([ tab_w/2, 0]) polygon(clip_profile);
            translate([-tab_w/2, 0]) mirror([1, 0, 0]) polygon(clip_profile);
            translate([0, -tab_h/2]) square([tab_w/2, 2*tab_h+overhang], center=true);
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
            translate([0, keyhole_h]) {
                hull() {
                    circle(d=suction_id+nozzle_d);
                    translate([0, -suction_id]) circle(d=suction_id+nozzle_d);
                }
                translate([0, -suction_id]) circle(d=suction_key+nozzle_d);
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
    
    module label() {
        label = "FASTRAK FLEX";
        typeface = "Liberation Sans:style=Bold";
        label_w = 10; // At size=1, the text is approximately 10 mm wide.
        type_size = (bracket_w-th)/label_w;
            text(label, font=typeface, size=type_size,
                 halign="center", valign="center");
    }
    
    module attrib() {
        label = "ADRIAN MCCARTHY";
        typeface = "Liberation Sans:style=Bold";
        label_w = 13.2;
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
    
    translate([0, -th, th-0.1]) {
        linear_extrude(2*layer_h+0.1, convexity=10) {
            translate([0, -(etag_w+2*th+etag_h/2)]) {
                label();
                translate([0, -(etag_h/2+2*th+etag_w+2*th+etag_h/2)]) {
                    attrib();
                }
            }
        }
    }
}

foldup_etag_bracket(layer_h=0.3);
