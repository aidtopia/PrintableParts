// Menu Panel
// Adrian McCarthy 2021

// A control panel to fit a 16x2 character LCD display and a rotary
// encoder.

use <aidbolt.scad>
use <aidutil.scad>


module menu_panel(nozzle_d=0.4) {
    // SparkFun Serial LCD board
    lcd_pcb_w       = 103;
    lcd_pcb_h       =  36;
    lcd_pcb_screws  = "M2.5";
    lcd_pcb_lr      = lcd_pcb_w - 5;
    lcd_pcb_ud      = lcd_pcb_h - 5;
    lcd_depth       =  7.05;
    lcd_w           = 71.5;
    lcd_h           = 26.75;
    lcd_x_offset    = 27;
    lcd_y_offset    =  4.26;

    // SparkFun rotary encoder with button and red/green LED on a breakout PCB.
    knob_pcb_w      = 16;
    knob_pcb_h      = 32;  // Actually shorter but this allows alternate orientation.
    knob_shaft_dia  =  7;
    knob_box_w      = 12.5;
    knob_box_h      = 13.25;
    knob_box_depth  =  2.4;

    tallest         = max(lcd_pcb_h, knob_pcb_h);
    wall_th         = 2;
    width           = wall_th + lcd_pcb_w + /* wall_th + knob_pcb_w */ + wall_th;
    height          = wall_th + tallest + wall_th;

    difference() {
        cube([width, height, wall_th]);
        translate([wall_th, wall_th, 0]) {
            translate([lcd_x_offset, lcd_y_offset, -1])
                cube([lcd_w, lcd_h, wall_th + 2]);
/*
            translate([lcd_pcb_w + wall_th, 0, 0]) {
                translate([knob_pcb_w/2, tallest/2, -1])
                    cylinder(h=wall_th+2, d=round_up(knob_shaft_dia, nozzle_d),
                             $fs=nozzle_d/2);
            }
*/
        }
    }
    translate([wall_th, wall_th, wall_th]) {
        translate([2.5, 0, 0]) {
            translate([0, 2.5, 0])         standoff("M2.5", 7 - wall_th);
            translate([0, lcd_pcb_h-2.5, 0]) standoff("M2.5", 7 - wall_th);
        }
        translate([lcd_pcb_w - 2.5, 0, 0]) {
            translate([0, 2.5, 0])         standoff("M2.5", 7 - wall_th);
            translate([0, lcd_pcb_h-2.5, 0]) standoff("M2.5", 7 - wall_th);
        }

/*
        translate([lcd_pcb_w + wall_th, wall_th, 0]) {
            difference() {
                cube([knob_pcb_w, knob_pcb_h, knob_box_depth]);
                translate([(knob_pcb_w - knob_box_w)/2, (tallest - knob_box_h)/2, -0.1])
                    cube([knob_box_w, knob_box_h, knob_box_depth+2]);
            }
        }
*/
    }
}

menu_panel();
