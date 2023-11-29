// Alternate shadow mask for Gemmy talking pumpkin
// Adrian McCarthy 2023-11-27

m2_free_d = 2.4;  // M2 screw "free fit" diameter

module shadow_mask(nozzle_d=0.4) {
    $fs = nozzle_d/2;

    mask_w = 52;
    mask_h = 116;
    mask_th = 1.2;  // original is only 0.65
    mask_r = 2;  // radius of rounded corners
    screw_dx = 46.5;
    screw_dy1 = 49.5;
    screw_dy2 = 60.5;
    
    // The LEDs are approximately 35, 75, and 95 mm up from the bottom.
    // We'll use those as the vertical offsets for the parts of the
    // faces.  Due to the projection angles, however, we need to bias
    // the open mouth shape up by 9 to 10 mm.
    eyeline_y = 95;  // approx
    mouthline_y1 = 75;  // approx
    mouthline_y2 = 35 + 10;  // approx
    
    // Derive vertical offsets for screw holes
    screw_y0 = (mask_h-(screw_dy1+screw_dy2))/2;
    screw_y1 = screw_y0 + screw_dy1;
    screw_y2 = screw_y1 + screw_dy2;
    
    module screw_pair() {
        d = m2_free_d + nozzle_d;
        translate([-screw_dx/2, 0]) circle(d=d);
        translate([ screw_dx/2, 0]) circle(d=d);
    }

    module rounded_rect(w, h, r, center=false) {
        nudge = center ? [0, 0] : [r, r];
        offset(r=r)
            translate(nudge)
                square([w-2*r, h-2*r], center=center);
    }

    module blank_plate() {
        difference() {
            translate([-mask_w/2, 0]) rounded_rect(mask_w, mask_h, mask_r);
            translate([0, screw_y0]) screw_pair();
            translate([0, screw_y1]) screw_pair();
            translate([0, screw_y2]) screw_pair();
        }
    }
    
    module eyes() {
        module eye() {
            translate([11, 0])
                rotate([0, 0, 97]) scale([1.0, 1.2]) circle(d=12, $fn=5);
        }
        
        translate([0, 5]) {
            eye();
            mirror([1, 0, 0]) eye();
        }
        rotate([0, 0, 90]) circle(d=10, $fn=3);
    }
    
    module teeth() {
        for (i=[-7:6]) {
            theta = 9*(i+0.5) + 2;
            q = cos(abs(theta));
            d = 11*q*q;
            rotate([0, 0, theta-90])
                translate([42/2, 0])
                    circle(d=d, $fn=3);
        }
    }
    
    module neutral_mouth() {
        difference() {
            circle(d=35);
            translate([0, 10]) circle(d=45);
            translate([0, 10]) teeth();
        }
    }
    
    module big_mouth() {
        difference() {
            circle(d=40);
            translate([0, 15]) circle(d=50);
            translate([0, 11]) teeth();
        }
    }
    
    linear_extrude(mask_th, convexity=10) {
        difference() {
            blank_plate();
            translate([0, eyeline_y]) eyes();
            translate([0, mouthline_y1]) neutral_mouth();
            translate([0, mouthline_y2]) big_mouth();
        }
    }
}

shadow_mask();

