// Control Panel for simple prop controller
// Adrian McCarthy 2023-02-12
//

module thread(h, tap_d, pitch, tooth_h, nozzle_d=0.4) {
    r = (tap_d + nozzle_d) / 2;

    facets =
        ($fn > 0) ? max(3, $fn)
                  : max(5, ceil(min(360/$fa, 2*PI*r / $fs)));
    dtheta = 360 / facets;
    echo(str("dtheta for threads = ", dtheta));

    module wedge() {
        rotate([1.5, 0, 0]) rotate([0, 0, -(dtheta+0.1)/2])
            rotate_extrude(angle=dtheta+0.1, convexity=10)
                translate([r, 0])
                    polygon([
                        [tooth_h, 0],
                        [0, -pitch/2],
                        [-0.1, -pitch/2],
                        [-0.1, pitch/2],
                        [0, pitch/2]
                    ]);
    }

    for (theta = [-180 : dtheta : h*360/pitch + 180]) {
        rotate([0, 0, theta]) translate([0, 0, pitch*theta/360])
            wedge();
    }
}

module prop_control_panel(panel_th=2, print_orientation=false, nozzle_d=0.4) {
    panel_w = 95;
    panel_h = 90;

    button_dia = 34;
    button_depth = 10;  // depth of the support

    module panel() {
        translate([0, 0, -panel_th/2])
            cube([panel_w, panel_h, panel_th]);
    }
    
    module brace(p0, p1) {
        brace_th = panel_th;
        translate([0, 0, -panel_th+0.1]) {
            linear_extrude(brace_th + 0.1, convexity=4, center=true) {
                hull() {
                    translate(p0) circle(d=brace_th, $fs=nozzle_d/2);
                    translate(p1) circle(d=brace_th, $fs=nozzle_d/2);
                }
            }
        }
    }

    function button_size() = [ 33.3, 33.3 ];

    module button_support() {
        translate([0, 0, panel_th/2 - button_depth])
            cylinder(h=button_depth, d=button_dia);
    }
    
    module button_cutout() {
        // Spec says it's M28x2
        // https://www.adafruit.com/product/3489
        // https://www.geocities.ws/qxb4tech/mthreadfine1_28.html
        tap_d = 26;
        pitch = 2;
        tooth_h = 1.227;
        translate([0, 0, panel_th/2 - button_depth - 0.1]) {
            cylinder(h=button_depth+0.2, d=tap_d + nozzle_d);
            intersection() {
                cylinder(h=button_depth-3, d=button_dia);
                thread(h=button_depth-3, tap_d=tap_d, pitch=pitch, tooth_h=tooth_h, nozzle_d=nozzle_d);
            }
            translate([0, 0, button_depth-3+0.1])
                cylinder(h=3+0.1, d=28);
        }
    }
    
    function relaymod_size() = [79, 43];

    module relaymod_cutout() {
        cutout_w = 75 + nozzle_d;
        cutout_h = 39 + nozzle_d;
        cube([cutout_w, cutout_h, panel_th+0.1], center=true);
    }
    
    module relaymod_bracing() {
        brace_th = panel_th;
        margin = max(min(4, brace_th), brace_th/2);
        left = -(relaymod_size().x/2 + margin);
        top = relaymod_size().y/2 + margin;
        right = -left;
        bottom = -top;
        
        brace([left, top], [left, bottom]);
        brace([left, bottom], [right, bottom]);
        brace([right, bottom], [right, top]);
        brace([right, top], [left, top]);
    }

    function rocker_size() = [15, 21];

    module rocker_cutout() {
        // Daier KCD-101 rocker switch
        // https://www.chinadaier.com/kcd1-101-10-amp-rocker-switch/
        cutout_w = 13.2;
        cutout_h = 19.2 + nozzle_d;
        cube([cutout_w, cutout_h, panel_th+0.1], center=true);
    }
    
    function recessed_rocker_size() = [rocker_size().x+panel_th, rocker_size().y+panel_th, 6];
    
    module recessed_rocker_support() {
        support_w = recessed_rocker_size().x + 2*panel_th;
        support_h = recessed_rocker_size().y + 2*panel_th;
        support_d = recessed_rocker_size().z + panel_th;
        translate([0, 0, (panel_th - support_d)/2])
            cube([support_w, support_h, support_d], center=true);
    }

    module recessed_rocker_cutout() {
        recess_w = recessed_rocker_size().x;
        recess_h = recessed_rocker_size().y;
        recess_d = recessed_rocker_size().z;
        translate([0, 0, (panel_th - recess_d)/2]) {
            cube([recess_w, recess_h, recess_d+0.1], center=true);
            translate([0, 0, -(recess_d+panel_th)/2]) rocker_cutout();
        }        
    }
    
    module terminal_block_support(channels=4) {
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
    rocker_pos =
        [relaymod_pos.x - relaymod_size().x/2 + rocker_size().x/2,
         relaymod_pos.y - relaymod_size().y/2 - rocker_size().y/2 - 8];
    
    //button_pos =
    //    [relaymod_pos.x + relaymod_size().x/2 - button_size().x/2,
    //     rocker_pos.y];

    recessed_pos =
        [relaymod_pos.x + relaymod_size().x/2 - recessed_rocker_size().x/2,
         rocker_pos.y];

    terminal_pos =
        [panel_w/2, relaymod_pos.y - relaymod_size().y/2 - 25];

    orient() {
        difference() {
            union() {
                panel();
                translate(relaymod_pos) relaymod_bracing();
                //translate(button_pos) button_support();
                translate(recessed_pos) recessed_rocker_support();
                translate(terminal_pos) terminal_block_support(4);
            }
            translate(relaymod_pos) relaymod_cutout();
            //translate(button_pos) button_cutout($fn=$preview ? 30 : 60);
            translate(rocker_pos) rocker_cutout();
            translate(recessed_pos) recessed_rocker_cutout();
        }
    }
}

//arcade_button_case($fn = $preview ? 30 : 60);
prop_control_panel(panel_th=1.8, print_orientation=!$preview);
