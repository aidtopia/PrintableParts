// Overhead camera mount for 2020 extrusion
// Adrian McCarthy 2023-03-26

// Show the quick release parts assembled.
Assembled = false;

// Include the overhead mount that holds a quick release plate?
Include_Mount = true;

// Style for the index pin.  "spring" is recommended for PETG but not PLA. "fixed" and "reinforced" restricts the plate to video cameras that have an opening for an index pin.
Index_Pin = "spring"; // ["none", "spring", "fixed", "reinforced"]

// Diameter of the nozzle you'll use to print.
Nozzle_Diameter = 0.4; // [0.1:0.05:1.0]


function inch(x) = 25.4 * x;

module rounded_rect(w, l, r=1, center=false, nozzle_d=0.4) {
    if (r > 0) {
        dx = w/2 - r;
        dy = l/2 - r;
        translate([center ? 0 : w/2, center ? 0 : l/2]) {
            hull($fs=nozzle_d/2) {
                translate([-dx, -dy]) circle(r=r);
                translate([-dx,  dy]) circle(r=r);
                translate([ dx,  dy]) circle(r=r);
                translate([ dx, -dy]) circle(r=r);
            }
        }
    } else {
        square([w, l], center=center);
    }
}

module spiral_arm(id, od, turns=1, th=undef, nozzle_d=0.4) {
    dtheta = 360*turns;
    arm_w = is_undef(th) ? nozzle_d : th;
    dr = (od - id)/2 + arm_w;
    arm = [each [for (theta=[0:12:dtheta])
                  let (r=id/2 + theta*dr/dtheta - arm_w,
                       x=r*cos(theta), y=r*sin(theta))
                  [x, y]],
           each [for (theta=[dtheta:-12:0])
                  let (r=id/2 + theta*dr/dtheta,
                       x=r*cos(theta), y=r*sin(theta))
                  [x, y]]
    ];
    polygon(arm);
}

m3_pilot_d =  2.5;
m3_free_d  =  3.4;
m3_head_d  =  6.0;
m3_head_h  =  2.4;

m5_pilot_d =  4.2;
m5_free_d  =  5.5;
m5_head_d  = 10.0;
m5_head_h  =  4.0;

// Based on Velbon quick-release QB-6RL
base0_w  = 47.8;
base0_l  = 68.7;
base0_h  =  4.0;
base0_z  =  0;

base1_w  = base0_w;
base1_l  = 63.6;
base1_h  =  5.5;
base1_z  = base0_z + base0_h;

slope_w1 = 61.6;
slope_w2 = 51.9;
slope_l  = 35.9;
slope_h1 =  1.8;
slope_h2 =  base0_h + base1_h;

slope_w  = max(slope_w1, slope_w2);

base_w   = max(base0_w, base1_w, slope_w);
base_l   = max(base0_l, base1_l);
base_h   = max(base0_h + base1_h, slope_h1, slope_h2);
base_z   = base0_z;

hollow_w = base1_w - 4;
hollow_l = base1_l - 2*m3_head_d;
hollow_h = base_h;

plate_w  = slope_w2;
plate_l  = 79.8;
plate_h  =  5.5;
plate_rim_h = 1;  // included in plate_h
plate_rim_th = 1;

// The camera bolt is 1/4"-20, partially threaded.
bolt_close_d = inch(0.266);
bolt_unthreaded_d = inch(0.188);
bolt_threaded_d = inch(0.226);
retainer_ids = [bolt_unthreaded_d, bolt_threaded_d];
retainer_od  = inch(0.400);
retainer_th  = 0.8;
retainer_open_angle = 75;

index_dy = -13.9;  // from bolt
index_d  =   5.0;
index_h  =  plate_h + 5;
index_spring_d = 13;
index_spring_h =  min(4, plate_h - plate_rim_h);
index_spring_arms = 3;

screws_dx = (base1_w - m3_head_d - 2)/2;
screws_dy = (base1_l - m3_head_d)/2;
screws_h  = 10;

cover_w  = plate_w - 2*plate_rim_th;
cover_l  = plate_l - 2*plate_rim_th;
cover_h  = plate_rim_h;

blob_d     = 4;
blob_delta = 8;
blob_dx    = screws_dx + 1;
blob_dy    = screws_dy + 5;

slope_profile = [
    [ slope_w1/2, 0],
    [ slope_w1/2, slope_h1],
    [ slope_w2/2, slope_h2],
    [-slope_w2/2, slope_h2],
    [-slope_w1/2, slope_h1],
    [-slope_w1/2, 0]
];

mount_th = 3;
mount_backing = mount_th + m5_head_h;
mount_w  = mount_th + max(plate_w, slope_w1, slope_w2) + mount_th;
mount_l  = mount_th + plate_l + slope_l;
mount_h  = mount_backing + base0_h + base1_h + plate_h - plate_rim_h;
mount_screws_dx = (hollow_w - m5_head_d)/2;

module velbon_qb_6rl(assembled=$preview, index_pin="spring", nozzle_d=0.4) {
    module M3_pilot_hole() {
        cylinder(screws_h+0.1, d=m3_pilot_d+nozzle_d, $fs=nozzle_d/2);
    }
    module M3_through_hole() {
        cylinder(screws_h+0.1, d=m3_free_d+nozzle_d, $fs=nozzle_d/2);
    }
    module M3_recessed_head() {
        cylinder(m3_head_h+0.2, d=m3_head_d+nozzle_d, $fs=nozzle_d/2);
    }

    module screws() {
        translate([-screws_dx, -screws_dy, 0]) children();
        translate([-screws_dx,  screws_dy, 0]) children();
        translate([ screws_dx, -screws_dy, 0]) children();
        translate([ screws_dx,  screws_dy, 0]) children();
    }
    
    // The blobs help align the cover on the plate and indicate good
    // places to apply adhesive.
    module blobs() {
        translate([-blob_delta, -blob_dy, 0]) children();
        translate([ blob_delta, -blob_dy, 0]) children();
        translate([-blob_delta,  blob_dy, 0]) children();
        translate([ blob_delta,  blob_dy, 0]) children();
        translate([-blob_dx, -blob_delta, 0]) children();
        translate([-blob_dx,  blob_delta, 0]) children();
        translate([ blob_dx, -blob_delta, 0]) children();
        translate([ blob_dx,  blob_delta, 0]) children();
    }

    module base() {
        difference() {
            union() {
                linear_extrude(base0_h)
                    rounded_rect(base0_w, base0_l, r=1, center=true);
                translate([0, 0, base1_z]) linear_extrude(base1_h)
                    rounded_rect(base1_w, base1_l, r=1, center=true);
                rotate([90, 0, 0]) linear_extrude(34.5, center=true) {
                    polygon(slope_profile);
                }
            }
            translate([0, 0, -0.1]) linear_extrude(hollow_h+0.2) {
                rounded_rect(hollow_w, hollow_l, r=1, center=true);
            }
            translate([0, 0, 1]) screws() { M3_pilot_hole(); }
        }
    }
    
    module plate() {
        face_z = plate_h - plate_rim_h;
        difference() {
            linear_extrude(plate_h, convexity=10) {
                difference() {
                    rounded_rect(plate_w, plate_l, r=4, center=true);
                    circle(d=bolt_close_d, $fs=nozzle_d/2);
                    translate([0, index_dy]) {
                        if (index_pin == "spring") {
                            circle(d=index_spring_d, $fs=nozzle_d/2);
                        }
                        if (index_pin == "reinforced") {
                            circle(d=1.6+nozzle_d, $fs=nozzle_d/2);
                        }
                    }
                }
            }
            translate([0, 0, face_z]) {
                linear_extrude(plate_rim_h+0.1) {
                    rounded_rect(cover_w, cover_l, r=4, center=true);
                }
            }
            translate([0, 0, -0.1]) {
                screws() {
                    M3_through_hole();
                    translate([0, 0, face_z-m3_head_h])
                        M3_recessed_head();
                }
            }
            translate([0, 0, face_z-retainer_th]) {
                cylinder(h=retainer_th+0.1, d=retainer_od+nozzle_d,
                         $fs=nozzle_d/2);
            }
            translate([0, 0, face_z]) {
                blobs() { sphere(d=blob_d+nozzle_d, $fs=nozzle_d/2); }
            }
        }
        
        ch = index_h-index_d/2;
        translate([0, index_dy, 0], $fs=nozzle_d/2) {
            if (index_pin == "spring") {
                linear_extrude(index_spring_h) {
                    dtheta = 360 / index_spring_arms;
                    for (theta = [dtheta:dtheta:360]) {
                        rotate([0, 0, theta])
                            spiral_arm(index_d, index_spring_d, th=1.5*nozzle_d);
                    }
                }
                cylinder(h=ch, d=index_d);
                translate([0, 0, ch/2]) sphere(d=index_d);
            }
            if (index_pin != "none") {
                difference() {
                    union() {
                        cylinder(h=ch, d=index_d);
                        translate([0, 0, ch]) sphere(d=index_d);
                    }
                    if (index_pin == "reinforced") {
                        translate([0, 0, -0.1])
                            cylinder(h=ch+0.1, d=1.6+nozzle_d, $fs=nozzle_d/2);
                    }
                }
            }
        }
    }
    
    module cover() {
        linear_extrude(cover_h, convexity=10) {
            difference() {
                rounded_rect(cover_w-nozzle_d, cover_l-nozzle_d, r=4,
                             center=true);
                circle(d=bolt_close_d+nozzle_d, $fs=nozzle_d/2);
                if (index_pin != "none") {
                    translate([0, index_dy])
                        circle(d=index_d+nozzle_d, $fs=nozzle_d/2);
                }
            }
        }
        intersection() {
            linear_extrude(blob_d, convexity=10) {
                square([cover_w, cover_l], center=true);
            }
            translate([0, 0, cover_h]) {
                blobs() { sphere(d=blob_d, $fs=nozzle_d/2); }
            }
        }
    }
    
    module retainer(retainer_id) {
        linear_extrude(retainer_th) {
            difference() {
                circle(d=retainer_od);
                circle(d=retainer_id+nozzle_d, $fs=nozzle_d/2);
                r = retainer_od/2;
                c = r * cos(retainer_open_angle/2);
                s = r * sin(retainer_open_angle/2);
                polygon([
                    [0, 0],
                    [c, s],
                    [r, s],
                    [r, -s],
                    [c, -s]
                ]);
            }
        }
    }
    
    base_x = assembled ? 0 : -(base_w/2 + 1 + plate_w/2);
    base_z = 0;
    translate([base_x, 0, base_z]) base();

    plate_x = 0;
    plate_z = assembled ? base_z+base_h : 0;
    translate([plate_x, 0, plate_z]) plate();

    retainer_x = assembled ? plate_x : base_x;
    retainer_y = assembled ? 0 : (len(retainer_ids)-1)*(retainer_od+nozzle_d)/2;
    retainer_z = assembled ? plate_z + plate_h - plate_rim_h : 0;
    translate([retainer_x, retainer_y, retainer_z]) {
        retainer(retainer_ids[0]);
        if (!assembled) {
            for (i = [1:len(retainer_ids)-1]) {
                translate([0, -i*(retainer_od+nozzle_d), 0])
                    retainer(retainer_ids[i]);
            }
        }
    }
    
    cover_rot_y = assembled ? 180 : 0;
    cover_x = assembled ? 0 : (plate_w/2 + 1 + cover_w/2);
    cover_z = assembled ? plate_z + plate_h - plate_rim_h + cover_h : 0;
    translate([cover_x, 0, cover_z]) rotate([0, cover_rot_y, 0]) cover();
}

module velbon_mount(nozzle_d=0.4) {
    // The envelope for the lowest part of the base creates an overhang.
    // Though the printer can generally handle it, it sags a little bit,
    // making the gap too tight.  This is a little extra clearance for
    // that spot.
    extra = nozzle_d;
    module envelope(r=4) {
        translate([0, 0, 0])
            linear_extrude(base0_h+nozzle_d+extra)
                offset(r=nozzle_d/2, $fs=nozzle_d/2)
                    square([base0_w, base0_l], center=true);

        translate([0, 0, nozzle_d/2])
            rotate([90, 0, 0])
                linear_extrude(slope_l+nozzle_d, center=true)
                    offset(r=nozzle_d/2, $fs=nozzle_d/2)
                        polygon(slope_profile);

        translate([0, 0, base0_h])
            linear_extrude(base1_h+nozzle_d)
                offset(r=nozzle_d/2, $fs=nozzle_d/2)
                    square([base1_w, base1_l], center=true);

        translate([0, 0, base_h])
            linear_extrude(plate_h+nozzle_d)
                offset(r=nozzle_d/2, $fs=nozzle_d/2)
                    rounded_rect(plate_w+nozzle_d, plate_l, r=r, center=true);
    }
    
    module escape() {
        linear_extrude(mount_h)
            projection()
                envelope(r=0);
    }

    difference() {
        linear_extrude(mount_h, convexity=10)
            rounded_rect(mount_w, mount_l, r=4, center=true);

        translate([0, (plate_l-mount_l)/2+mount_th, mount_backing]) {
            envelope();
            translate([0, slope_l-nozzle_d/2, 0]) escape();
        }
        
        for (i = [-1:2:1]) {
            translate([mount_screws_dx*i, 0, 0]) {
                translate([0, 0, -0.1])
                    cylinder(h=mount_h+0.2, d=m5_free_d+nozzle_d,
                             $fs=nozzle_d/2);
                // We cheat on the depth of the recess for the screw
                // head in order to have a little more backing for the
                // screw to hold.  If the head isn't perfectly flush,
                // we're still okay because they're placed in the
                // "hollow" of the mounting plate.
                cheat = nozzle_d;
                translate([0, 0, mount_backing - m5_head_h + cheat])
                    cylinder(h=m5_head_h+0.1, d=m5_head_d+nozzle_d,
                             $fs=nozzle_d/2);
            }
        }
    }
}

velbon_qb_6rl(assembled=Assembled, index_pin=Index_Pin, nozzle_d=Nozzle_Diameter);
if (Include_Mount) {
    translate([0, plate_l/2 + 2 + mount_w/2, 0]) rotate([0, 0, 90])
        velbon_mount(nozzle_d=Nozzle_Diameter);
}
