// PIR bake-off bracket
// Adrian McCarthy 2021

use <aidbolt.scad>
use <aidutil.scad>

module PIR_tester(sensors, wall_th=2, nominal_spacing=40, nozzle_d=0.4) {
    // The labels are engraved on the inside.  When illuminated from within,
    // they appear on the outside.
    label_h = 10;
    label_th = round_up(1, nozzle_d);  // just thick enough to be opaque

    // The baffles are interior walls to partition the light for each indicator.
    baffle_th = label_th;
    baffle_depth = 25;
    
    count = len(sensors);

    // We round the actual spacing up to a multiple of 2.54mm (0.1") to align
    // each unit to breadboard or perfboard spacing.
    spacing = round_up(nominal_spacing, 2.54);
    unit = spacing - baffle_th;

    // overall dimensions
    width = wall_th + unit*count + baffle_th*(count - 1) + wall_th;
    height = unit + baffle_th + label_h + wall_th;
    depth = 30;
    
    assert(width < 220, "too wide to print on Ultimaker 2");

    // Because we're working from inside, we work right-to-left
    function x_center(i) = width - wall_th - i*spacing - unit/2;

    module center_over_sensor(i) {
        translate([x_center(i), unit/2, 0]) {
            children();
        }
    }
    
    module center_over_label(i) {
        translate([x_center(i), unit + baffle_th + label_h/2, 0]) {
            children();
        }
    }

    difference() {
        cube([width, height, depth]);
        translate([wall_th, -0.1, wall_th])
            cube([width-2*wall_th, unit+0.1, depth]);
        
        translate([wall_th, -wall_th, wall_th+baffle_depth])
            cube([width-2*wall_th, height, depth]);
    
        for (i=[0:count-1]) {
            sensor = sensors[i];
            center_over_sensor(i) {
                // Opening for PIR's lens:
                lens_d = round_up(sensor[1], nozzle_d);
                translate([0, 0, -1])
                    cylinder(d=lens_d, h=wall_th+2, $fs=nozzle_d/2);
            }
            
            // Indicator label that appears when illuminated from inside.
            center_over_label(i) {
                // Hollow out the volume behind the label.
                translate([-unit/2, -label_h/2, label_th])
                    cube([unit, label_h, depth]);
                // The label itself.
                translate([0, -label_h/5, 0.3]) color("red")
                    linear_extrude(wall_th, convexity=10) mirror([1, 0])
                        text(sensor[0], size=0.45*label_h,
                             font="Trebuchet",
                             halign="center", valign="baseline",
                             $fs=nozzle_d/2);
            }
        }
    }
    
    // Standoffs.
    for (i=[0:len(sensors)-1]) {
        sensor = sensors[i];
        center_over_sensor(i) {
            screw   = sensor[2];
            screw_l = sensor[3];
            lr      = sensor[4];
            ud      = sensor[5];
            
            if (screw != "") translate([0, 0, wall_th]) {
                if (lr != 0) {
                    translate([-lr, -ud]) standoff(screw, screw_l);
                    translate([ lr, -ud]) standoff(screw, screw_l);
                }
                if (ud != 0) {
                    translate([-lr,  ud]) standoff(screw, screw_l);
                    translate([ lr,  ud]) standoff(screw, screw_l);
                }
            }
        }
    }
}

PIR_tester(
    sensors=[
        //                          ------------standoffs--------------
        // model            lens_d  size    height  left/right  up/down
        ["Adafruit 189",    23.5,   "M2.5", 4.0,    28.5/2,     0       ],
        ["Adafruit 4871",   12.5,   "",     0.0,    0,          0       ],
        ["HC-SR501",        23.5,   "M2",   4.0,    29/2,       0       ],
        ["Parallax",        23.5,   "M2.5", 3.5,    29.5/2,     0       ],
        ["SparkFun",        22.5,   "M2.5", 5.0,    23/2,       27.5/2  ]
    ]
);
