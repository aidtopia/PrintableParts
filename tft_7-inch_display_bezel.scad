// Bezel for 7" TFT display from Adafruit
// Adrian McCarthy 2022-09-01

// Use M3x5mm screws to attach the retaining straps to the back
// of the frame using appropriate heat-set inserts (e.g.,
// McMaster-Carr 94180A333).
//
// Can mount to a VESA 100 with M4x10mm screws into the standoffs
// using appropriate heat-set inserts (e.g.,
// McMaster-Carr 94180A351).
//
// Considering also adding a way to mount the Adafruit RA8875
// breakout board used to drive the display.

use <aidbolt.scad>
use <aiddin.scad>

// Choose the type of mount you want on the back of the assembly.
Mount_Type = "vesa"; // ["din", "vesa"]

module END_OF_CUSTOMIZER_PARAMETERS() {}

// Reference for VESA mount parameters:
// https://www.ergotron.com/en-us/support/vesa-standard
vesa_mounts = [
//   name                 x    y  bolt  bolt_l
    ["50x20 (MIS-B)",    50,  20, "M4",  6],
    ["75x35 (MIS-C)",    75,  35, "M4",  8],
    ["VESA75 (MIS-D)",   75,  75, "M4", 10],
    ["VESA100 (MIS-D)", 100, 100, "M4", 10],  // <--
    ["200x100 (MIS-E)", 200, 100, "M4", 10],
    ["VESA200 (MIS-F)", 200, 200, "M6", 10],  // bolt_l = 8 or 10
    ["VESA400 (MIS-F)", 400, 400, "M8", 15]
];

module bezel(mount="vesa") {
    wall_th = 2;
    // The datasheet calls the metal plate the LCM outline.
    plate_w  = 164.9 + 0.3;
    plate_h  = 100.0 + 0.3;
    plate_th =   3.4 + 0.2;
    screen_w = 154.08;
    screen_h =  88.92;
    screen_x =  -6.9;
    screen_y =   4.78;
    device_th = plate_th + 1.4;
    flex_w   =  89;
    flex_h   =  55;

    // The pcb is the Adafruit RA8875 driver board.
    pcb_w  =  50;
    pcb_h  =  40;
    pcb_th =   1.6;
    pcb_offset_x = 38;
    pcb_offset_y = -plate_h/2 + pcb_h/2 + flex_h;
    
    vesa_index = 3;
    vesa_offset_x = vesa_mounts[vesa_index][1]/2;
    vesa_offset_y = vesa_mounts[vesa_index][2]/2;
    vesa_bolt     = vesa_mounts[vesa_index][3];
    vesa_bolt_l   = vesa_mounts[vesa_index][4];

    bolt = "M3";  // for connecting the retaining straps to the frame
    bolt_l = 5;

    bolt_d = max(boss_diameters(bolt)[0], boss_diameters(vesa_bolt)[0]);

    screw = "M2";  // for connecting the PCB
    screw_l = 10;
    screw_offset_x = 43/2;
    screw_offset_y = 36/2;
    
    frame_w = wall_th + plate_w + abs(screen_x) + wall_th;
    frame_h =
        wall_th + bolt_d + plate_h + abs(screen_y) + bolt_d + wall_th;
    frame_th = wall_th + device_th;
    
    bolt_offset_x = vesa_offset_x;
    bolt_offset_y = (frame_h - bolt_d - wall_th) / 2;
    
    strap_th = max(wall_th, bolt_l - frame_th + 1);
    strap_w  = bolt_d + wall_th/2;    

    module strap(mount="vesa") {
        
        module basic_strap(rounded=true) {
            difference() {
                linear_extrude(strap_th) hull() {
                    for (y = [-bolt_offset_y, bolt_offset_y])
                        translate([0, y, 0])
                            if (rounded)
                                circle(d=strap_w);
                            else
                                square(strap_w, center=true);
                }
                translate([0, 0, strap_th]) {
                    translate([0, -bolt_offset_y, 0])
                        bolt_hole(bolt, bolt_l, threads="none");
                    translate([0,  bolt_offset_y, 0])
                        bolt_hole(bolt, bolt_l, threads="none");
                }
            }
        }

        module din_mount() {
            din_w = wall_th + 35 + wall_th;
            din_depth = 8;
            din_lift = 3;
            din_h = din_lift + 1 + wall_th;

            difference() {
                translate([0, 0, din_h/2])
                    cube([strap_w, din_w, din_h], center=true);
                translate([0, 0, din_lift])
                rotate([0, -90, 0])
                translate([din_depth, 0, 0])
                    AD_din_cutout(length=strap_w+1, center=true);
            }
        }
        
        if (mount == "vesa") {
            union() {
                basic_strap();
                for (y = [-vesa_offset_y, vesa_offset_y])
                    translate([0, y, strap_th])
                        standoff(vesa_bolt, vesa_bolt_l, threads="insert");
            }
        } else if (mount == "din") {
            translate($preview ? [0, 0, 0] : [0, 0, strap_w/2])
            rotate($preview ? [0, 0, 0] : [0, -90, 0])
            union() {
                basic_strap(rounded=false);
                din_mount();
            }
        }
    }

    module frame() {
        difference() {
            translate([0, 0, frame_th/2]) rotate([0, 180, 0])
            difference() {
                full_th = frame_th;// + strap_th;

                // Start with a slab.
                translate([0, 0, (frame_th - full_th)/2])
                    cube([frame_w, frame_h, full_th], center=true);

                // Form a recess for the plate.
                translate([-screen_x/2, -screen_y/2, -wall_th])
                    cube([plate_w, plate_h, full_th], center=true);

                // Cut an opening to see the screen.
                cube([screen_w, screen_h, full_th + 2], center=true);

                // Notch out a relief for the flex cable.
                translate([0, -frame_h/2+1, -wall_th])
                    cube([flex_w, frame_h/2 + 2, full_th], center=true);
            }
            
            // Bore mounting holes for the straps.
            translate([0, 0, frame_th])
            for (x=[-bolt_offset_x, bolt_offset_x])
                for (y=[-bolt_offset_y, bolt_offset_y])
                    translate([x, y, 0])
                        bolt_hole(bolt, bolt_l-strap_th, threads="insert");
            // Add some credits.
            translate([0, -frame_h/2+18, wall_th])
                linear_extrude(wall_th, center=true, convexity=10)
                    text("7\" TFT Display Bezel", 5, halign="center", valign="top");
            translate([0, -frame_h/2+8, wall_th])
                linear_extrude(wall_th, center=true, convexity=10)
                    text("Adrian McCarthy 2022", 5, halign="center", valign="top");
                
            // Label the bolt holes.
            translate([-bolt_offset_x-strap_w/2, 0, frame_th]) {
                translate([0, -bolt_offset_y, 0])
                    linear_extrude(wall_th, center=true, convexity=10)
                        text("M3", 4, halign="right", valign="center");
                translate([0,  bolt_offset_y, 0])
                    linear_extrude(wall_th, center=true, convexity=10)
                        text("M3", 4, halign="right", valign="center");
            }
            translate([ bolt_offset_x+strap_w/2, 0, frame_th]) {
                translate([0, -bolt_offset_y, 0])
                    linear_extrude(wall_th, center=true, convexity=10)
                        text("M3", 4, halign="left", valign="center");
                translate([0,  bolt_offset_y, 0])
                    linear_extrude(wall_th, center=true, convexity=10)
                        text("M3", 4, halign="left", valign="center");
            }
        }
    }
    
    module pcb() {
        color("blue")
        cube([pcb_w, pcb_h, pcb_th], center=true);
    }
    
    module pcb_holes() {
        for (x=[-screw_offset_x, screw_offset_x])
            for (y=[-screw_offset_y, screw_offset_y])
                translate([x, y, 0])
                    bolt_hole(screw, screw_l, threads="self-tapping");
    }

    frame();

    translate($preview ? [0, 0, frame_th] : [0, 0, 0])
    rotate($preview ? [0, 0, 0] : [0, 0, 90])
    union() {
        x = $preview ? bolt_offset_x : (strap_w + 1)/2;
        translate([-x, 0, 0]) strap(mount=mount);
        translate([ x, 0, 0]) strap(mount=mount);
    }
    if (false && $preview) {
        translate([0, 0, strap_th]) {
            translate([pcb_offset_x, pcb_offset_y, pcb_th/2]) {
                difference() {
                    pcb();
                    translate([0, 0, pcb_th/2]) pcb_holes();
                }
            }
        }
    }
}

bezel(mount=Mount_Type);
