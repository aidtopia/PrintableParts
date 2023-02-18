// Control Panel for simple prop controller
// Adrian McCarthy 2023-02-12

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
        rotate([1.35, 0, 0])
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


// Arcade Button
// https://www.adafruit.com/product/3489
//
function arcadebtn_size(panel_th=0) = [ 33.3, 33.3, 10 ];

module arcadebtn_support(panel_th, nozzle_d=0.4) {
    button_dia   = arcadebtn_size().x;
    button_depth = arcadebtn_size().z;
    translate([0, 0, panel_th/2 - button_depth])
        cylinder(h=button_depth, d=button_dia);
}

module arcadebtn_cutout(panel_th, nozzle_d=0.4) {
    button_dia   = arcadebtn_size().x;
    button_depth = arcadebtn_size().z;

    translate([0, 0, panel_th/2 - button_depth - 0.1]) {
        // threading stops 3 mm short of the bezel
        tap(h=button_depth-3+0.2, d=28, pitch=2, nozzle_d=nozzle_d);
        translate([0, 0, button_depth-3+0.1])
            cylinder(h=3+0.1, d=28);
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


// Relay Module
// XY-WJ01 Programmable Relay
// https://www.mpja.com/download/35874rldata.pdf
function relaymod_size(panel_th=0) = [79, 43];

module relaymod_cutout(panel_th, nozzle_d=0.4) {
    cutout_w = 75 + nozzle_d;
    cutout_h = 39 + nozzle_d;
    cube([cutout_w, cutout_h, panel_th+0.1], center=true);
}

module relaymod_bracing(panel_th, nozzle_d=0.4) {
    brace_th = panel_th;
    margin = max(min(4, brace_th), brace_th/2);
    left = -(relaymod_size().x/2 + margin);
    top = relaymod_size().y/2 + margin;
    right = -left;
    bottom = -top;

    module brace(p0, p1) {
        translate([0, 0, -panel_th+0.1]) {
            linear_extrude(brace_th + 0.1, convexity=4, center=true) {
                hull() {
                    translate(p0) circle(d=brace_th, $fs=nozzle_d/2);
                    translate(p1) circle(d=brace_th, $fs=nozzle_d/2);
                }
            }
        }
    }

    brace([left, top],     [left, bottom]);
    brace([left, bottom],  [right, bottom]);
    brace([right, bottom], [right, top]);
    brace([right, top],    [left, top]);
}


// Rocker Switch
// Daier KCD-101 rocker switch
// https://www.chinadaier.com/kcd1-101-10-amp-rocker-switch/
function rocker_size(panel_th=0) = [15, 21];

module rocker_cutout(panel_th, nozzle_d=0.4) {
    cutout_w = 13.2;
    cutout_h = 19.2 + nozzle_d;
    cube([cutout_w, cutout_h, panel_th+0.1], center=true);
}

function recessed_rocker_size(panel_th) = [
    rocker_size(panel_th).x + panel_th,
    rocker_size(panel_th).y + panel_th, 6
];

module recessed_rocker_support(panel_th, nozzle_d=0.4) {
    support_w = recessed_rocker_size(panel_th).x + 2*panel_th;
    support_h = recessed_rocker_size(panel_th).y + 2*panel_th;
    support_d = recessed_rocker_size(panel_th).z + panel_th;
    translate([0, 0, (panel_th - support_d)/2])
        cube([support_w, support_h, support_d], center=true);
}

module recessed_rocker_cutout(panel_th, nozzle_d=0.4) {
    recess_w = recessed_rocker_size(panel_th).x;
    recess_h = recessed_rocker_size(panel_th).y;
    recess_d = recessed_rocker_size(panel_th).z;
    translate([0, 0, (panel_th - recess_d)/2]) {
        cube([recess_w, recess_h, recess_d+0.1], center=true);
        translate([0, 0, -(recess_d+panel_th)/2])
            rocker_cutout(panel_th, nozzle_d);
    }        
}
    

// Terminal Block
// This is for smallish "European" style screw terminals.
module terminal_block_support(channels=4, panel_th, nozzle_d=0.4) {
    terminal_w = 6;
    spacer_w   = 3.5;
    support_w = terminal_w*channels + spacer_w*(channels-1);
    support_h = 17;
    support_d = 4;
    translate([0, 0, -(support_d + panel_th)/2]) {
        difference() {
            cube([support_w, support_h, support_d], center=true);
            translate([0, 0, -panel_th]) {
                for (i = [0:2:channels]) {
                    dx = (terminal_w + spacer_w)*i/2;
                    translate([dx, 0, 0])
                        cylinder(d=2.5 + nozzle_d/2, h=10, center=true, $fs=nozzle_d/2);
                    translate([-dx, 0, 0])
                        cylinder(d=2.5 + nozzle_d/2, h=10, center=true, $fs=nozzle_d/2);
                }
            }
        }
    }
}

module prop_control_panel(
    panel_w=100, panel_h=100, panel_th=2,
    print_orientation=false,
    nozzle_d=0.4
) {
    module panel() {
        translate([0, 0, -panel_th/2])
            cube([panel_w, panel_h, panel_th]);
    }
    
    module orient() {
        if (print_orientation) {
            translate([panel_w, 0, panel_th/2]) rotate([0, 180, 0]) {
                children();
            }
        } else {
            children();
        }
    }
    
    relaymod_pos = [panel_w/2, panel_h-relaymod_size().y/2 - 10, 0];
    recessed_pos =
        [relaymod_pos.x + relaymod_size().x/2 - recessed_rocker_size(panel_th).x/2,
         relaymod_pos.y - relaymod_size().y/2 - rocker_size().y/2 - 8];
    button_pos =
        [relaymod_pos.x - relaymod_size().x/2 + metalbtn_size().x/2,
         recessed_pos.y];

    orient() {
        difference() {
            union() {
                panel();
                translate(relaymod_pos)
                    relaymod_bracing(panel_th, nozzle_d);
                translate(button_pos)
                    metalbtn_support(panel_th, nozzle_d);
                translate(recessed_pos)
                    recessed_rocker_support(panel_th, nozzle_d);
            }
            translate(relaymod_pos)
                relaymod_cutout(panel_th, nozzle_d);
            translate(button_pos)
                metalbtn_cutout(panel_th, nozzle_d);
            translate(recessed_pos)
                recessed_rocker_cutout(panel_th, nozzle_d);
        }
    }
}

prop_control_panel(panel_th=1.8, print_orientation=!$preview);
