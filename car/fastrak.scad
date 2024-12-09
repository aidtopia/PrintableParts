// Bracket to hold FasTrak Flex transponder to windshield with suction cup.
// Adrian McCarthy 2023-06-20

etag_l = 111;
etag_w = 36;
etag_h = 15;

etag_logo_l = 35;
etag_logo_h = 28;
    
module etag_bracket2(th=2, nozzle_d=0.4) {
    suction_od = 30;
    suction_id = 6.5;
    suction_key = 10.5;
    suction_dx = max(suction_od, etag_l/1.5)/2;
    
    keyhole_h = suction_key/2 + suction_id;

    $fs = nozzle_d/2;

    module keyhole() {
        hull() {
            circle(d=suction_id + nozzle_d);
            translate([0, -keyhole_h])
                circle(d=suction_id + nozzle_d);
        }
        translate([0, -keyhole_h])
            circle(d=suction_key + nozzle_d);
    }
    
    module slot() {
        hull() {
            circle(d=suction_key + nozzle_d);
            translate([0, -keyhole_h])
                circle(d=suction_key + nozzle_d);
        }
    }
    
    module logo_window() {
        offset(th) offset(-th)
            square([etag_logo_l, etag_logo_h], center=true);
    }

    linear_extrude(2, convexity=10) {
        difference() {
            offset(r=th+nozzle_d/2)
                square([etag_l, etag_w], center=true);
            translate([-suction_dx, 0]) keyhole();
            translate([ suction_dx, 0]) keyhole();
            logo_window();
        }
    }
    translate([0, 0, 2]) {
        linear_extrude(5, convexity=10) {
            difference() {
                offset(r=th+nozzle_d/2)
                    square([etag_l, etag_w], center=true);
                translate([-suction_dx, 0]) slot();
                translate([ suction_dx, 0]) slot();
                logo_window();
            }
        }
        translate([0, 0, 5]) {
            difference() {
                linear_extrude(etag_h+nozzle_d, convexity=10) {
                    difference() {
                        offset(r=th+nozzle_d/2)
                            square([etag_l, etag_w], center=true);
                        offset(r=nozzle_d/2)
                            square([etag_l, etag_w], center=true);
                    }
                }
                translate([0, etag_w/2, etag_h/2+nozzle_d]) {
                    rotate([90, 0, 0]) {
                        linear_extrude(etag_w, convexity=4, center=true) {
                            offset(r=th+nozzle_d/2)
                                offset(r=-th)
                                    square([etag_l, etag_h], center=true);
                        }
                    }
                }
            }
            translate([0, 0, etag_h+nozzle_d/2]) {
                linear_extrude(th, convexity=10) {
                    difference() {
                        offset(r=th+nozzle_d/2)
                            square([etag_l, etag_w], center=true);
                        polygon([
                            [-(etag_l-1*th)/2, etag_w/2+th+nozzle_d],
                            [-(etag_l-4*th)/2, -etag_w/2],
                            [ (etag_l-4*th)/2, -etag_w/2],
                            [ (etag_l-1*th)/2, etag_w/2+th+nozzle_d]
                        ]);
                    }
                }
            }
        }
    }
}

// This version is too flimsy.
module foldup_etag_bracket(th=2, layer_h=0.2, nozzle_d=0.4) {
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


module etag_bracket_upright(th=2, nozzle_d=0.4) {
    // Depsite overhangs, it might be better for heat dissipation and strength
    // to print upright rather than on its back.
    translate([0, 0, etag_h+2*th+nozzle_d])
        rotate([90, 0, 0])
            etag_bracket2(th=th, nozzle_d=nozzle_d);
}

etag_bracket_upright();
