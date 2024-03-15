// Control Panel for simple prop controller
// Adrian McCarthy 2023-02-12

use <aidthread.scad>

function inch(x) = 25.4*x;

module brace(p0, p1, brace_th=2, nozzle_d=0.4) {
    linear_extrude(brace_th + 0.1, convexity=4, center=true) {
        hull() {
            translate(p0) circle(d=brace_th, $fs=nozzle_d/2);
            translate(p1) circle(d=brace_th, $fs=nozzle_d/2);
        }
    }
}

module rectangular_brace(size, panel_th, nozzle_d=0.4) {
    brace_th = panel_th;
    margin = max(min(4, brace_th), brace_th/2);
    left    = -(size.x/2 + margin);
    top     = size.y/2 + margin;
    right   = -left;
    bottom  = -top;
    translate([0, 0, -panel_th+0.1]) {
        brace([left, top],     [left, bottom],  brace_th, nozzle_d);
        brace([left, bottom],  [right, bottom], brace_th, nozzle_d);
        brace([right, bottom], [right, top],    brace_th, nozzle_d);
        brace([right, top],    [left, top],     brace_th, nozzle_d);
    }
}


// DC Jack
// 
function dcjack_size(panel_th=0) = [ 12.4, 12.4, 4 ];

module dcjack_support(panel_th, nozzle_d=0.4) {
    support_dia  = dcjack_size().x + 2;
    jack_depth = dcjack_size().z;
    translate([0, 0, panel_th/2 - jack_depth])
        cylinder(h=jack_depth, d=support_dia);
}

module dcjack_cutout(panel_th, nozzle_d=0.4) {
    jack_dia   = dcjack_size().x;
    jack_depth = dcjack_size().z;
    translate([0, 0, panel_th/2 - jack_depth - 0.1]) {
        AT_threads(h=jack_depth + 0.2, d=12, pitch=1, tap=true,
                   nozzle_d=nozzle_d);
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
        translate([0, 0, button_depth-3])
            cylinder(h=3+panel_th/2+0.2, d=28);
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
        AT_threads(h=button_depth + 0.2, d=12, pitch=0.75, tap=true,
                   nozzle_d=nozzle_d);
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


function fuse_holder_size(panel_th=0)
    = [25+2*panel_th, 12.5+2*panel_th, 10];

module fuse_holder_support(panel_th, nozzle_d=0.4) {
    l = fuse_holder_size(panel_th).x;
    w = fuse_holder_size(panel_th).y;
    h = fuse_holder_size(panel_th).z;
    dia = 8.25;
    translate([0, 0, -panel_th/2 - h]) {
        difference() {
            linear_extrude(h+0.1, convexity=10) {
                difference() {
                    square([l, w], center=true);
                    square([25, 12.5], center=true);
                }
            }
            translate([0, 0, 1.5+dia/2]) {
                hull() {
                    rotate([0, 90, 0])
                        cylinder(h=l+0.2, d=dia, center=true);
                    translate([0, 0, -dia/2])
                        cube([l+0.2, dia, dia], center=true);
                }
            }
        }
    }
}

// Relay Module
// XY-WJ01 Programmable Relay
// https://www.mpja.com/download/35874rldata.pdf
function relaymod_size(panel_th=0) = [79, 43];

module relaymod_support(panel_th, nozzle_d=0.4) {
    rectangular_brace(relaymod_size(), panel_th, nozzle_d);
}

module relaymod_cutout(panel_th, nozzle_d=0.4) {
    cutout_w = 75 + nozzle_d;
    cutout_h = 39 + nozzle_d;
    cube([cutout_w, cutout_h, panel_th+0.1], center=true);
}


// Rocker Switch
// Daier KCD-101 rocker switch
// https://www.chinadaier.com/kcd1-101-10-amp-rocker-switch/
function rocker_size(panel_th=0) = [15, 21];

module rocker_support(panel_th, nozzle_d=0.4) {
    rectangular_brace(rocker_size(), panel_th, nozzle_d);
}

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
module terminal_block_support(channels=4, panel_th=2, nozzle_d=0.4) {
    terminal_w = 6;
    spacer_w   = 3.5;
    support_w = terminal_w*channels + spacer_w*(channels-1);
    support_h = 20;
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
    panel_w=inch(4+1/16), panel_h=inch(4+1/16), panel_th=2,
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
    
    relaymod_pos =
        [panel_w/2, 3/4*panel_h];
    button_pos =
        [relaymod_pos.x + relaymod_size().x/2 - metalbtn_size(panel_th).x/2,
         relaymod_pos.y - relaymod_size().y/2 - metalbtn_size(panel_th).y/2 - 10];
    rocker_pos =
        [relaymod_pos.x - relaymod_size().x/2 + metalbtn_size().x/2,
         button_pos.y + metalbtn_size(panel_th).y/2 - metalbtn_size().y/2];
    jack_pos = [
        rocker_pos.x - rocker_size().x/2 + dcjack_size().x/2,
        rocker_pos.y - rocker_size().y/2 - dcjack_size().y/2 - 8
    ];
    fuse_pos = [panel_w - fuse_holder_size(panel_th).x/2 - 16, fuse_holder_size(panel_th).y/2 + 6];

    orient() {
        difference() {
            union() {
                panel();
                translate(relaymod_pos)
                    relaymod_support(panel_th, nozzle_d);
                translate(button_pos)
                    metalbtn_support(panel_th, nozzle_d);
                translate(rocker_pos)
                    rocker_support(panel_th, nozzle_d);
                translate(jack_pos)
                    dcjack_support(panel_th, nozzle_d);
                translate(fuse_pos)
                    fuse_holder_support(panel_th, nozzle_d);
            }
            translate(relaymod_pos)
                relaymod_cutout(panel_th, nozzle_d);
            translate(button_pos)
                metalbtn_cutout(panel_th, nozzle_d);
            translate(rocker_pos)
                rocker_cutout(panel_th, nozzle_d);
            translate(jack_pos)
                dcjack_cutout(panel_th, nozzle_d);
        }
    }
}

prop_control_panel(panel_th=1.8, print_orientation=!$preview);
