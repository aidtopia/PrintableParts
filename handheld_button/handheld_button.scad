// Handheld Button
// Adrian McCarthy 2023-03-12
//
// Useful for game-show signaling buttons, Halloween prop triggers,
// nurse call buttons, etc.

// High-Amp Button
// https://www.amazon.com/gp/product/B08QV4CWYW
// https://www.chinadaier.com/19mm-push-button-switch/

// Diameter of the body of the button just below the panel. (mm)
Button_Body_Diameter = 19;  // [5:0.5:30]

// Diameter of the flange of the selected button. (mm)
Button_Flange_Diameter = 21.8; // [10:0.1:35]

// Height of the support that holds the button. Should be less than the threaded portion of the button body. (mm)
Button_Support_Height = 5; // [3:1:10]

// Distance from thread to thread on body of the button. (mm)
Button_Thread_Pitch = 1; // [0.5:0.25:3]

// If there's a gap in the threads just below the flange, put its height here. (mm)
Button_Threadless_Height = 1; // [0:0.1:5]

// Diameter of the opening at the small end of the case. (mm)
Cable_Diameter = 6; // [3:0.2:10]

// Thickness of the case. (mm)
Thickness = 2; // [1.2:0.2:4]

// Diameter of the nozzle used for printing. If unknown, the 0.4 mm default is probably fine. (mm)
Nozzle_Diameter = 0.4; // [0.15:0.05:1]

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

    module wedge() {
        // TODO:  Figure out how to compute `magic_rotation` angle
        // from the thread pitch and wedge size.  This tilts the
        // wedges so they align well with each other.  The hardcoded
        // value was determined empirically and is probably only
        // appropriate for the threading parameters I've been testing
        // with.
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
module handheld_button(
    panel_th=2,
    button_body_d=19,
    button_flange_d=21.8,
    button_support_h=5,
    button_thread_pitch=1,
    button_threadless_h=1,
    small_id=6,
    nozzle_d=0.4
) {
    case_id = button_flange_d - panel_th;
    case_od = case_id + 2*panel_th;
    inset_d = button_flange_d;
    inset_h = button_support_h - panel_th;
    straight_h = 25;
    taper_h = 50;
    total_h = straight_h + taper_h;
    small_od = small_id + 2*panel_th;
    brim_d = min(case_od, 2*small_od);
    
    module case() {
        stop_h = 3*panel_th;
        stop_d = small_id + stop_h/taper_h * (case_id - small_id);

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
                [stop_d/2, stop_h],
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
        body_d = button_body_d;
        support_d = button_flange_d;
        support_h = button_support_h;
        threadless_h = button_threadless_h;

        translate([0, 0, panel_th/2]) rotate([180, 0, 0]) {
            difference() {
                union() {
                    // lip
                    difference() {
                        cylinder(h=panel_th, d=case_od, center=true);
                        translate([0, 0, -panel_th])
                            cylinder(h=panel_th, d=case_id);
                    }
                    // support for the body of the button
                    translate([0, 0, panel_th/2-support_h])
                        cylinder(h=support_h, d=support_d);
                }
                translate([0, 0, panel_th/2-support_h-0.1]) {
                    // cut threads into the support
                    tap(h=support_h+0.2, d=body_d,
                        pitch=button_thread_pitch, nozzle_d=nozzle_d);
                    if (threadless_h > 0) {
                        translate([0, 0, support_h-threadless_h])
                            cylinder(h=threadless_h+panel_th/2+0.1, d=body_d);
                    }
                }
            }
        }
    }
    
    offset = (case_od + brim_d)/2 + 1; 
    translate([0, offset, 0]) case();
    top();
}

handheld_button(
    panel_th=Thickness,
    button_body_d=Button_Body_Diameter,
    button_flange_d=Button_Flange_Diameter,
    button_support_h=Button_Support_Height,
    button_thread_pitch=Button_Thread_Pitch,
    button_threadless_h=Button_Threadless_Height,
    small_id=Cable_Diameter,
    nozzle_d=Nozzle_Diameter,
    $fn=$preview ? 30 : 60
);


// Parameters for other buttons:

// Metal Button
// https://www.chinadaier.com/gq12h-10m-momentary-push-button-switch/
//   Spec says M12 without specifying pitch.  Using microscope and test
////   prints, I determined it's 0.75.
// Button_Body_Diameter = 12;
// Button_Flange_Diameter = 13.9;
// Button_Support_Height = 5;
// Button_Thread_Pitch = 0.75;
// Button_Threadless_Height = 1;

// Arcade Button
// https://www.adafruit.com/product/3489
//
// Button_Body_Diameter = 28;
// Button_Flange_Diameter = 33.3;
// Button_Support_Height = 10;
// Button_Thread_Pitch = 2;
// Button_Threadless_Height = 3;
