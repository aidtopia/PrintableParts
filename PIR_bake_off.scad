// PIR bake-off bracket
// Adrian McCarthy 2021

use <aidbolt.scad>
use <aidutil.scad>

module PIR_tester(sensors, thickness=2.4, spacing=40, nozzle_d=0.4) {
    led_d = round_up(5.5, nozzle_d);

    width = spacing*len(sensors);
    height = spacing + 10;
    depth = 25.4;

    difference() {
        // Face plate
        cube([width, height, thickness]);

        for (i=[0:len(sensors)-1]) {
            sensor = sensors[i];
            translate([i*spacing + spacing/2, spacing/2, 0]) {
                // Opening for PIR's lens:
                lens_d = round_up(sensor[1], nozzle_d);
                translate([0, 0, -1])
                    cylinder(d=lens_d, h=thickness+2, $fs=nozzle_d/2);

                // Labels
                translate([0, spacing/2, 0.4]) {
                    linear_extrude(thickness, convexity=10)
                        text(sensor[0], size=5, font="Trebuchet", halign="center", $fs=nozzle_d/2);
                }

            }
        }

        // Holes for mounting screws
        for (i = [0:len(sensors)-1]) {
            sensor = sensors[i];
            translate([i*spacing + spacing/2, spacing/2, 0]) {
                screw  = sensor[2];
                screw_l = 5;
                lr     = sensor[3];
                ud     = sensor[4];
                if (screw != "") translate([0, 0, thickness]) {
                    if (lr != 0) {
                        translate([-lr, -ud]) bolt_hole(screw, screw_l);
                        translate([ lr, -ud]) bolt_hole(screw, screw_l);
                    }
                    if (ud != 0) {
                        translate([-lr,  ud]) bolt_hole(screw, screw_l);
                        translate([ lr,  ud]) bolt_hole(screw, screw_l);
                    }
                }
            }
        }

        // Branding.
        translate([spacing*len(sensors)/2, 1, 0.4])
            linear_extrude(2+1, convexity=10)
                text("HAYWARD HAUNTER", size=7, font="Century Gothic:style=Bold", halign="center");
    }
}

PIR_tester(
    sensors=[
        ["Adafruit 189",    23.5,   "M2.5",     28.5/2,     0],
        ["Adafruit 4871",   12.3,   "",         0,          0],
        ["HC-SR501",        23.5,   "M2",       29/2,       0],
        ["Parallax",        23.5,   "M2.5",     29.5/2,     0],
        ["SparkFun",        22.5,   "M2.5",     23/2,  27.5/2]
    ]
);
