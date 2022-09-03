// Bezel for 7" TFT display from Adafruit
// Adrian McCarthy 2022-09-01

use <aidbolt.scad>

module bezel() {
    wall_th = 2;
    // The datasheet calls the metal plate the LCM outline.
    plate_w  = 164.9 + 0.3;
    plate_h  = 100.0 + 0.3;
    plate_th = 3.4 + 0.2;
    screen_w = 154.08;
    screen_h =  88.92;
    screen_x =  -6.9;
    screen_y =   4.78;
    device_th = plate_th + 1.4;
    flex_w   =  50;
    flex_h   =  55;
    pcb_w  =  50;
    pcb_h  =  40;
    pcb_th =   1.6;
    pcb_offset_x = 38;
    pcb_offset_y = -plate_h/2 + pcb_h/2 + flex_h;
    
    bolt = "M3";  // for connecting retainer to frame
    bolt_l = 5;
    bolt_d = boss_diameters(bolt)[0];
    
    screw = "M2";  // for connecting pcb to retainer
    screw_l = 10;
    screw_offset_x = 43/2;
    screw_offset_y = 36/2;
    
    frame_w = wall_th + plate_w + wall_th + abs(screen_x);
    frame_h = wall_th + plate_h + wall_th + abs(screen_y) + 2*bolt_d;
    frame_th = device_th + wall_th;
    
    retainer_w  = frame_w;
    retainer_th = max(wall_th, bolt_l - frame_th + 1);
    beam_d = bolt_d + wall_th/2;

    vesa_offset_x = 100/2;
    vesa_offset_y = 100/2;

    bolt_offset_x = vesa_offset_x;
    bolt_offset_y = (frame_h - bolt_d - wall_th) / 2;
   
    
    module frame() {
        translate([0, 0, frame_th/2]) rotate([0, 180, 0])
        difference() {
            cube([frame_w, frame_h, frame_th], center=true);
            translate([-screen_x/2, -screen_y/2, -wall_th])
                cube([plate_w, plate_h, frame_th], center=true);
            cube([screen_w, screen_h, frame_th + 2], center=true);
            translate([0, -frame_h/2+1, -wall_th])
                cube([flex_w, frame_h/2 + 2, frame_th], center=true);
        }
    }
    
    module retainer() {
        module beam_ends(offset_x) {
            translate([offset_x, -bolt_offset_y, 0])
                circle(d=beam_d);
            translate([offset_x,  bolt_offset_y, 0])
                circle(d=beam_d);
        }
        module beam(offset_x) {
            hull() beam_ends(offset_x);
        }
        linear_extrude(retainer_th, convexity=10) {
            beam(-bolt_offset_x);
            beam( bolt_offset_x);
        }
    }
    
    module pcb() {
        color("blue")
        cube([pcb_w, pcb_h, pcb_th], center=true);
    }
    
    module retainer_holes(threads="self-tapping") {
        for (x=[-bolt_offset_x, bolt_offset_x])
            for (y=[-bolt_offset_y, bolt_offset_y])
                translate([x, y, 0])
                    bolt_hole(bolt, bolt_l, threads=threads);
    }

    module pcb_holes() {
        for (x=[-screw_offset_x, screw_offset_x])
            for (y=[-screw_offset_y, screw_offset_y])
                translate([x, y, 0])
                    bolt_hole(screw, screw_l, threads="self-tapping");
    }

    module vesa() {
        linear_extrude(20, convexity=10)
            for (x=[-vesa_offset_x, vesa_offset_x])
                for (y=[-vesa_offset_y, vesa_offset_y])
                    translate([x, y, 0]) circle(d=4);
    }

    difference() {
        frame();
        translate([0, 0, frame_th + retainer_th])
            retainer_holes();
    }

    y = $preview ? 0 : (frame_h + 1) / 2;
    z = $preview ? frame_th : 0;

    translate([0, y, z]) {
        difference() {
            retainer();
            translate([0, 0, retainer_th]) {
                retainer_holes(threads="none");
                translate([pcb_offset_x, 0, pcb_th])
                    pcb_holes();
            }
        }
        translate([pcb_offset_x, pcb_offset_y, retainer_th + pcb_th/2])
        if ($preview) {
            difference() {
                pcb();
                translate([0, 0, pcb_th/2]) pcb_holes();
            }
        }
    }
    
    #vesa();
}

bezel();
