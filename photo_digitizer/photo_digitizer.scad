// Parts for photo digitizer
// Adrian McCarthy 2024-01-29
// with Jason Adler

function cumulative_sum(layers) = [
  for (i = 0, h = 0; i < len(layers); h = h + layers[i], i = i+1) h
];

function inch(x) = 25.4 * x;

layers = [
    [40, 40, 0.9], // accommodates 127 aperture
    [50, 50, 1.8], // 2"x2" slide mount
    [inch(5), inch(3), 0.9],
    [inch(6), inch(4), 0.9],
    [inch(7), inch(5), 0.9]
];
w = max([for (layer=layers) layer.x]);
h = max([for (layer=layers) layer.y]);
lift = cumulative_sum([for (layer=layers) layer.z]);
total_lift = lift[len(lift)-1] + layers[len(layers)-1].z;

border = 5;
rim_h = max(5, total_lift);
rim_th = 2;
frame_th = 2;
frame_h = 160;

module rim(nozzle_d=0.4) {
    linear_extrude(rim_h) difference() {
        offset(r=border) square([w, h], center=true);
        offset(r=border-rim_th) square([w, h], center=true);
    }
}

module tab(nozzle_d=0.4) {
    d = 20;
    module tab_footprint() {
        hull() {
            translate([-d/2, 0]) circle(d=d);
            translate([-nozzle_d/2, 0]) square([nozzle_d, 2*d], center=true);
        }
    }

    difference() {
        linear_extrude(rim_h) tab_footprint();
        translate([0, 0, 0.5*rim_h])
            linear_extrude(rim_h) offset(r=-rim_th) tab_footprint();
    }
}

module photo_plate(clearance=undef, nozzle_d=0.4) {
    c = is_undef(clearance) ? nozzle_d/2 : clearance;
    difference() {
        for (i = [0:len(layers)-1]) {
            translate([0, 0, lift[i]]) {
                linear_extrude(layers[i].z) {
                    difference() {
                        offset(r=border) square([w, h], center=true);
                        square([layers[i].x+c, layers[i].y+c], center=true);
                    }
                }
            }
        }
        
        // Holes to extract slides
        translate([0,  25, lift[1]]) cylinder(h=total_lift+2, d=15);
        translate([0, -25, lift[1]]) cylinder(h=total_lift+2, d=15);

        // Holes to make it easy to remove photos by poking them from below.
        translate([ w/4, 0, -1]) cylinder(h=total_lift+2, d=15);
        translate([-w/4, 0, -1]) cylinder(h=total_lift+2, d=15);
    }
    rim(nozzle_d=nozzle_d);
    translate([-w/2-(border-rim_th), 0]) tab(nozzle_d=nozzle_d);
}

module logitech_brio_plate(nozzle_d=0.4) {
    base_th = 1.2;
    camera_support_th = 2;
    camera_support_h = 12;

    module lozenge() {
        d = 27;  // diameter of circular "ends" of camera
        l = 102;  // full length of camera
        dx = (l - d) / 2;
        hull() {
            translate([-dx, 0]) circle(d=d, $fn=50);
            translate([ dx, 0]) circle(d=d, $fn=50);
        }
    }

    linear_extrude(base_th) {
        difference() {
            offset(r=5) square([w, h], center=true);
            circle(d=10+nozzle_d);
        }
    }
    rim(nozzle_d=nozzle_d);
    translate([0, 0, base_th]) {
        linear_extrude(camera_support_h) {
            difference() {
                offset(r=camera_support_th) lozenge();
                offset(r=nozzle_d/2) lozenge();
            }
        }
    }
}

module frame(nozzle_d=0.4) {
    linear_extrude(frame_th) {
        difference() {
            offset(r=2*border) square([w, h], center=true);
            offset(r=-border) square([w, h], center=true);
        }
    }
    translate([0, 0, frame_th]) {
        linear_extrude(rim_h+0.3) {
            difference() {
                offset(r=2*border) square([w, h], center=true);
                offset(r=border) square([w, h], center=true);
                translate([-w/2, 0]) square([4*border, h+2*border], center=true);
            }
        }
    }
}

if ($preview) {
    color("yellow") frame();
    translate([0, 0, frame_th]) {
        color("orange") translate([0, 0, 0.1]) photo_plate(clearance=0.3);
        //color("blue") translate([0, 0, frame_h]) logitech_brio_plate();
    }
} else {
    photo_plate();
}

