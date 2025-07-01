// Parts for photographic slide digitizer
// Adrian McCarthy 2025-06-18
// Based on a more general photo digitizer collaboration with Jason Adler.

function cumulative_sum(layers) = [
  for (i = 0, h = 0; i < len(layers); h = h + layers[i], i = i+1) h
];

function inch(x) = 25.4 * x;

layers = [
    [40, 40, 0.9], // accommodates 127 aperture
    [40, 40, 0.9], // duplicated for easier extraction
    [50, 50, 1.8], // 2"x2" slide mount
    [80, 80, 0.9]
];
  
// TODO:  Is the depth of the pocket for the slides enough to handle both
// GEPE and Wess Plastics slide mounts?
  
w = max([for (layer=layers) layer.x]);
h = max([for (layer=layers) layer.y]);
lift = cumulative_sum([for (layer=layers) layer.z]);
total_lift = lift[len(lift)-1] + layers[len(layers)-1].z;

border = 4;
rim_h = max(5, total_lift);
rim_th = 2;
frame_th = 2;
frame_h = 160;

// Right now, I'm using an old Lumix "travel zoom" camera.  It has a flat
// face except for a circular ring around the lens, which gives us a way to
// align the camera's optical center to that of the slide.
lumix_d = 46.5;  // circular bit surrounding the lens on the pink Lumix camera

// We want to hold the camera as close to the slide as possible in order to
// capture the entire image frame and to be within the focus range of the
// camera (which has some macro capability, but not a lot).  In all instances,
// we'll assume the camera is zoomed all the way out.  Note that you can also
// set the aspect ratio captured by the Lumix.  In both cases, the limit factor
// is the ability to focus up close.  But that point varies with the selected
// aspect ratio, so it's worth have different box heights for different slide
// formats.
lumix40_h = 62;  // 40x40mm frame using Lumix's 1:1 aspect ratio.
lumix35_h = 49;  // ~35x24mm frame using 3:2 aspect ratio.  Too close for 4:3.

// Note, either the whole thing needs to be adjustable, or a separate box
// with a shorter height would be desirable to take full advantage of the
// camera's resolution when digitizing standard 35mm slides.

// TODO:  Figure out a way to restrict rotation of the camera.

box_d1 = max(lumix_d, sqrt(layers[0].x*layers[0].x + layers[0].y*layers[0].y));
box_d2 = lumix_d;
box_h = lumix35_h;  //lumix40_h;

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
                        offset(r=c) square([layers[i].x, layers[i].y], center=true);
                    }
                }
            }
        }
        
        // Recesses at the corners make it easy to remove a slide.  They
        // also keep the corners from getting too tight because of printing
        // imperfections.
        translate([ 26,  26, lift[1]]) cylinder(h=total_lift+2, d=15);
        translate([-26,  26, lift[1]]) cylinder(h=total_lift+2, d=15);
        translate([ 26, -26, lift[1]]) cylinder(h=total_lift+2, d=15);
        translate([-26, -26, lift[1]]) cylinder(h=total_lift+2, d=15);
    }
    rim(nozzle_d=nozzle_d);
    translate([-w/2-(border-rim_th), 0]) tab(nozzle_d=nozzle_d);
}

module box(clearance=undef, nozzle_d=0.4) {
    c = is_undef(clearance) ? nozzle_d/2 : clearance;
    h1 = rim_h + c;
    h2 = box_h - 2*(rim_h + c);
    h3 = rim_h;
    z0 = 0;
    z1 = z0 + h1;
    z2 = z1 + h2;
    d1 = box_d1 + 2*c;
    d2 = box_d2 + 2*c;
    difference() {
        linear_extrude(box_h, convexity=4) {
            offset(r=2*border) square([w, h], center=true);
        }
        translate([0, 0, z0-1]) cylinder(h=h1+1.01, d=d1);
        translate([0, 0, z1  ]) cylinder(h=h2,      d1=d1, d2=d2);
        translate([0, 0, z2-1]) cylinder(h=h3+2, d=d2);
        translate([0, 0, z0-1]) linear_extrude(h1+1, convexity=4) hull() {
            offset(r=border+c) square([w, h], center=true);
            translate([-w, 0]) offset(r=border+c) square([w, h], center=true);
        }
    }
}

// The slides are nominally 50x50mm.  The cardboard mounts are typically
// a smidge smaller than that, and we want a snug fit.  But there are
// small variations in the mounts from batch to batch, so we apply a
// clearance that's a little more than the default we'd use just for
// printer tolerance.
slide_clearance = 0.3;  // maybe even 0.4?

echo(w);

if ($preview) {
    color("orange") translate([0, 0, 0.1]) photo_plate(clearance=slide_clearance);
    color("yellow") box();
} else {
    photo_plate(clearance=slide_clearance);
    translate([w+4*border, 0, box_h]) rotate([0, 180, 0]) box();
}
