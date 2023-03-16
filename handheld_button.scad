// Handheld Button
// Adrian McCarthy 2023-03-12
//
// Useful for game-show signaling buttons, Halloween prop triggers,
// etc.

// Diameter of the opening at the small end of the case. (mm)
Cable_Diameter = 6; // [3:0.2:10]

function inch(x) = 25.4*x;

// This creates a tap for cutting an internal thread.  (A nut has
// an internal thread.  A bolt has an external thread.)
// https://en.wikipedia.org/wiki/ISO_metric_screw_thread
module tap(h, d, pitch, nozzle_d=0.4) {
    // An M3 screw has a major diameter of 3 mm.  We're going to
    // nudge it up with the nozzle diameter to compensate for
    // the problem of printing accurate holes and to generally
    // provide some clearance.
    d_major = d + nozzle_d;
    thread_h = pitch / (2*tan(30));
    d_minor = d_major - 2 * (5/8) * thread_h;
    d_max = d_major + thread_h/8;
    
    echo(str("M", d, "x", pitch, ": thread_h=", thread_h, "; d_major=", d_major, "; d_minor=", d_minor));

    x_major = 0;
    x_deep  = x_major + thread_h/8;
    x_minor = x_major - 5/8*thread_h;
    x_clear = x_minor - thread_h/4;
    y_major = pitch/16;
    y_minor = 3/8 * pitch;
    
    wedge_points = [
        [x_deep, 0],
        [x_minor, y_minor],
        [x_minor, pitch/2],
        [x_clear, pitch/2],
        [x_clear, -pitch/2],
        [x_minor, -pitch/2],
        [x_minor, -y_minor]
    ];

    r = d_major / 2;

    facets =
        ($fn > 0) ? max(3, $fn)
                  : max(5, ceil(min(360/$fa, 2*PI*r / $fs)));
    dtheta = 360 / facets;
    echo(str("dtheta for threads = ", dtheta));

    module wedge() {
        // TODO:  Figure out how to compute `magic_rotation` angle
        // from the thread pitch and wedge size.  This tilts the
        // wedges so they meet align well.
        magic_rotation = 1.35;
        rotate([magic_rotation, 0, 0])
            rotate([0, 0, -(dtheta+0.1)/2])
                rotate_extrude(angle=dtheta+0.1, convexity=10)
                    translate([r, 0])
                        polygon(wedge_points);
    }

    intersection() {
        union() {
            for (theta = [-180 : dtheta : h*360/pitch + 180]) {
                rotate([0, 0, theta]) translate([0, 0, pitch*theta/360])
                    wedge();
            }
            
            cylinder(h=h, d=d_minor);
        }
        cylinder(h=h, d=d_max + nozzle_d);
    }
}

// Metal Button
// https://www.chinadaier.com/gq12h-10m-momentary-push-button-switch/
// Spec says M12 without specifying pitch.  Per an answer on an
// Amazon page, the pitch is 1.0 mm, which is "extra fine" (and hard to
// find).  Under the microscope, it looks like 0.75.
function metalbtn_size(panel_th=0) = [ 13.9, 13.9, 4 ];

module metalbtn_support(panel_th, nozzle_d=0.4) {
    support_dia  = metalbtn_size().x + 2;
    button_depth = metalbtn_size().z;
    translate([0, 0, panel_th/2 - button_depth])
        cylinder(h=button_depth, d=support_dia);
}

module metalbtn_cutout(panel_th, nozzle_d=0.4) {
    button_dia   = metalbtn_size().x;
    button_depth = metalbtn_size().z;
    translate([0, 0, panel_th/2 - button_depth - 0.1]) {
        tap(h=button_depth + 0.2, d=12, pitch=0.75, nozzle_d=nozzle_d);
    }
}

// High-Amp Button
// https://www.amazon.com/gp/product/B08QV4CWYW
// https://www.chinadaier.com/19mm-push-button-switch/
// M19x1
function hiampbtn_size(panel_th=0) = [ 21.8, 21.8, 5 ];

module hiampbtn_support(panel_th, nozzle_d=0.4) {
    support_dia  = hiampbtn_size().x;
    button_depth = hiampbtn_size().z;
    translate([0, 0, panel_th/2 - button_depth])
        cylinder(h=button_depth, d=support_dia);
}

module hiampbtn_cutout(panel_th, nozzle_d=0.4) {
    button_dia   = hiampbtn_size().x;
    button_depth = hiampbtn_size().z;
    translate([0, 0, panel_th/2 - button_depth - 0.1]) {
        tap(h=button_depth + 0.2, d=19, pitch=1, nozzle_d=nozzle_d);
        translate([0, 0, button_depth-1])
            cylinder(h=1+panel_th/2+0.1, d=19);
    }
}


// I've had good results with this in PLA or PETG.  The top that
// has the threads for the button should be sliced with 0.2 mm
// layers (or better).  The case can be sliced with 0.3 mm layers
// for faster printing.
//
// The button body screws into the top piece (flange to flange).
// The rubber ring that comes with the button can be squeezed
// between the flanges for a bit of a seal.  You probably should
// not need the jam nut that comes with the button.  In fact it's
// likely too wide to fit inside the case.
//
// Feed the wires up through the small end of the case and make
// the appropriate connections.  There's enough room inside the
// case to add a diode or resistor.  Use a small (e.g., 4-inch)
// cable tie around the incoming wires as a strain relief.  The
// tie will be too large to be tugged through the narrow end.
//
// The top fits into the case with a friction fit.  You could
// attach it permanently with a couple drops of CA glue.
module handheld_button(panel_th=2, small_id=6, nozzle_d=0.4) {
    case_id = hiampbtn_size().x - panel_th;
    case_od = case_id + 2*panel_th;
    inset_d = hiampbtn_size().x;
    inset_h = hiampbtn_size().z - panel_th;
    straight_h = 25;
    taper_h = 50;
    total_h = straight_h + taper_h;
    small_od = small_id + 2*panel_th;
    brim_d = min(case_od, 2*small_od);
    
    module case() {
        inset_d = hiampbtn_size().x;
        inset_h = hiampbtn_size().z - panel_th;
        straight_h = 25;
        stop_h = 3*panel_th;

        rotate_extrude()
            polygon([
                [small_id/2, 0],
                [small_od/2, 0],
                [case_od/2, taper_h],
                [case_od/2, taper_h+straight_h],
                [inset_d/2, taper_h+straight_h],
                [inset_d/2, taper_h+straight_h-inset_h],
                [case_id/2, taper_h+straight_h-inset_h],
                [case_id/2, taper_h],
                [small_id/2, stop_h],
                [small_id/2, 0]
            ]);

        // The object above has a tiny footprint, so it doesn't always
        // stick reliably to the build plate.  We can't print it upside
        // down because the inset would become an overhang.  I don't
        // want to mess with slicer settings, so I'm adding a brim here
        // in the design.
        linear_extrude(nozzle_d/2) {
            difference() {
                circle(d=brim_d);
                circle(d=small_id);
            }
        }
    }
    
    module top() {
        translate([0, 0, panel_th/2]) rotate([180, 0, 0]) {
            difference() {
                union() {
                    difference() {
                        cylinder(h=panel_th, d=case_od, center=true);
                        translate([0, 0, -panel_th])
                            cylinder(h=panel_th, d=case_id);
                    }
                    hiampbtn_support(panel_th, nozzle_d);
                }
                hiampbtn_cutout(panel_th, nozzle_d);
            }
        }
    }
    
    offset = (case_od + brim_d)/2 + 1; 
    translate([0, offset, 0]) case();
    top();
}

handheld_button(small_id=Cable_Diameter, $fn=$preview ? 30 : 60);
