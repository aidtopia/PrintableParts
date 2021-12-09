// PIR bake-off bracket
// Adrian McCarthy 2021

use <aidbolt.scad>
use <aidutil.scad>

module PIR_tester(sensors, thickness=2.4, spacing=40, nozzle_d=0.4) {
    unit = spacing - thickness;
    width = thickness + spacing*len(sensors);
    label_h = 10;
    height = thickness + unit + thickness + label_h + thickness;
    depth = 25.4;

    led_d = round_up(5.2, nozzle_d);

    function x_center(i) = thickness + i*spacing + unit/2;

    module center_over_sensor(i) {
        translate([x_center(i), thickness + unit/2, 0]) {
            children();
        }
    }
    
    module center_over_label(i) {
        translate([x_center(i), thickness + spacing + label_h/2, 0]) {
            children();
        }
    }

    difference() {
        cube([width, height, depth]);
        translate([thickness, -thickness, thickness])
            cube([width-2*thickness, spacing+0.1, depth]);
        translate([thickness, unit, thickness+2/3*depth])
            cube([width-2*thickness, thickness + label_h + thickness, depth]);
    
        for (i=[0:len(sensors)-1]) {
            sensor = sensors[len(sensors) - 1 - i];
            center_over_sensor(i) {
                // Opening for PIR's lens:
                lens_d = round_up(sensor[1], nozzle_d);
                translate([0, 0, -1])
                    cylinder(d=lens_d, h=thickness+2, $fs=nozzle_d/2);
            }
            
            // Indicator label that appears when illuminated from inside.
            center_over_label(i) {
                // Hollow out the volume behind the label.
                translate([-unit/2, -label_h/2, thickness/2])
                    cube([unit, label_h, 2/3*depth - thickness]);
                // The label itself.
                #translate([0, -label_h/5, 0.3])
                    linear_extrude(thickness, convexity=10) mirror([1, 0, 0])
                        text(sensor[0], size=0.45*label_h,
                             font="Trebuchet",
                             halign="center", valign="baseline",
                             $fs=nozzle_d/2);
                translate([0, 0, depth/2]) {
                    translate([-4*2.54, 0, 0]) cylinder(h=depth, d=led_d, $fs=nozzle_d/2);
                                               cylinder(h=depth, d=led_d, $fs=nozzle_d/2);
                    translate([ 4*2.54, 0, 0]) cylinder(h=depth, d=led_d, $fs=nozzle_d/2);
                }
            }
        }
    }
    
    // Standoffs.
    for (i=[0:len(sensors)-1]) {
        sensor = sensors[len(sensors) - 1 - i];
        center_over_sensor(i) {
            screw   = sensor[2];
            screw_l = sensor[3];
            lr      = sensor[4];
            ud      = sensor[5];
            
            if (screw != "") translate([0, 0, thickness]) {
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
        //                          standoffs
        // model            lens_d  size    height  left/right  up/down
        ["Adafruit 189",    23.5,   "M2.5", 4.0,    28.5/2,     0       ],
        ["Adafruit 4871",   12.3,   "",     0.0,    0,          0       ],
        ["HC-SR501",        23.5,   "M2",   4.0,    29/2,       0       ],
        ["Parallax",        23.5,   "M2.5", 3.5,    29.5/2,     0       ],
        ["SparkFun",        22.5,   "M2.5", 5.0,    23/2,       27.5/2  ]
    ]
);
