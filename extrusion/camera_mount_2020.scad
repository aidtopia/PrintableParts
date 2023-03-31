// Overhead camera mount for 2020 extrusion
// Adrian McCarthy 2023-03-26

function inch(x) = 25.4 * x;

module rounded_rect(w, l, r=1, center=false, nozzle_d=0.4) {
    dx = w/2 - r;
    dy = l/2 - r;
    translate([center ? 0 : w/2, center ? 0 : l/2]) {
        hull($fs=nozzle_d/2) {
            translate([-dx, -dy]) circle(r=r);
            translate([-dx,  dy]) circle(r=r);
            translate([ dx,  dy]) circle(r=r);
            translate([ dx, -dy]) circle(r=r);
        }
    }
}

module spiral_arm(id, od, turns=1, nozzle_d) {
    dtheta = 360*turns;
    dr = (od - id)/2 + nozzle_d;
    arm = [each [for (theta=[0:12:dtheta])
                  let (r=id/2 + theta*dr/dtheta - nozzle_d,
                       x=r*cos(theta), y=r*sin(theta))
                  [x, y]],
           each [for (theta=[dtheta:-12:0])
                  let (r=id/2 + theta*dr/dtheta,
                       x=r*cos(theta), y=r*sin(theta))
                  [x, y]]
    ];
    polygon(arm);
}

// Based on Velabon quick-release QB-6RL
base0_w  = 47.8;
base0_l  = 68.7;
base0_h  =  4.0;
base0_z  =  0;

base1_w  = base0_w;
base1_l  = 63.6;
base1_h  =  5.5;
base1_z  = base0_z + base0_h;

slope_w1 = 61.6;
slope_w2 = 51.9;
slope_l  = 35.9;
slope_h1 =  1.8;
slope_h2 =  base0_h + base1_h;

plate_w  = slope_w2;
plate_l  = 79.8;
plate_h  =  5.5;
plate_z  = base1_z + base1_h;
plate_rim = 1;  // included in plate_h

// The camera bolt is 1/4"-20, partially threaded.
bolt_close_d = inch(0.266);
retainer_id  = inch(0.220);
retainer_od  = inch(0.400);
retainer_th  = 0.8;
retainer_open_angle = 30;

index_dy = -13.9;  // from bolt
index_d  =   4.0;
index_spring_d = 12;
index_spring_h =  4;
index_spring_arms = 3;

m3_pilot_d = 2.5;
m3_free_d  = 3.4;
m3_head_d  = 6.0;
m3_head_h  = 2.4;

screws_dx = (plate_w - 8)/2;
screws_dy = (plate_l - 8)/2;

cover_w  = plate_w - 2;
cover_l  = plate_l - 2;
cover_h  = plate_rim;

slope_profile = [
    [61.5/2, 0],
    [61.5/2, 1.75],
    [52/2, 10],
    [-52/2, 10],
    [-61.5/2, 1.75],
    [-61.5/2, 0]
];

module velebon_qb_6rl(nozzle_d=0.4) {
    module M3_pilot_hole() {
        cylinder(10+0.1, d=2.5+nozzle_d, $fs=nozzle_d/2);
    }
    module M3_through_hole() {
        cylinder(10+0.1, d=3.4+nozzle_d, $fs=nozzle_d/2);
    }
    module M3_recessed_head() {
        cylinder(2.4+0.2, d=6.0+nozzle_d, $fs=nozzle_d/2);
    }

    module screws() {
        dx = (44-6)/2;
        dy = (64-6)/2;
        translate([-dx, -dy, 0]) children();
        translate([-dx,  dy, 0]) children();
        translate([ dx, -dy, 0]) children();
        translate([ dx,  dy, 0]) children();
    }

    module base() {
        difference() {
            union() {
                linear_extrude(4) rounded_rect(48, 69, r=1, center=true);
                linear_extrude(10) rounded_rect(48, 64, r=1, center=true);
                rotate([90, 0, 0]) linear_extrude(34.5, center=true) {
                    polygon(slope_profile);
                }
            }
            translate([0, 0, -0.1]) linear_extrude(10+0.2) {
                rounded_rect(44, 52, r=1, center=true);
            }
            translate([0, 0, 1]) screws() { M3_pilot_hole(); }
        }
    }
    
    module plate() {
        difference() {
            linear_extrude(6, convexity=10) {
                difference() {
                    rounded_rect(52, 80, r=4, center=true);
                    circle(d=inch(0.266), $fs=nozzle_d/2);
                    translate([0, -13.9]) circle(d=12, $fs=nozzle_d/2);
                }
            }
            translate([0, 0, -0.1]) {
                screws() {
                    M3_through_hole();
                    translate([0, 0, 5-2.4]) M3_recessed_head();
                }
            }
            translate([0, 0, 5]) {
                linear_extrude(1+0.1) {
                    rounded_rect(52-2, 80-2, r=4, center=true);
                }
            }
            translate([0, 0, 5-0.8]) {
                cylinder(h=0.8+0.1, d=inch(0.400)+nozzle_d, $fs=nozzle_d/2);
            }
        }
        
        // springy index pin
        translate([0, -13.9, 0], $fs=nozzle_d/2) {
            linear_extrude(5) {
                spiral_arm(4, 12, nozzle_d=nozzle_d);
                rotate([0, 0, 120]) spiral_arm(4, 12, nozzle_d=nozzle_d);
                rotate([0, 0, 240]) spiral_arm(4, 12, nozzle_d=nozzle_d);
            }
            cylinder(h=9, d=4);
            translate([0, 0, 9]) sphere(d=4);
        }
    }
    
    module surface() {
        linear_extrude(1, convexity=10) {
            difference() {
                rounded_rect(52-2-nozzle_d, 80-2-nozzle_d, r=4,
                             center=true);
                circle(d=inch(0.400)+nozzle_d, $fs=nozzle_d/2);
                translate([0, -13.9])
                    circle(d=4+nozzle_d, $fs=nozzle_d/2);
            }
        }
    }
    
    module retainer() {
        od = inch(0.400);
        id = inch(0.220);
        linear_extrude(0.8) {
            difference() {
                circle(d=od);
                circle(d=id+nozzle_d, $fs=nozzle_d/2);
                polygon([
                    [0, 0],
                    [4*od, 3*od],
                    [4*od, -3*od]
                ]);
            }
        }
    }
    
    base();
    retainer();
    translate([62, 0, 0]) plate();
    translate([120, 0, 0]) surface();
}

module velabon_mount(nozzle_d=0.4) {
    th = 3;
    intersection() {
        cube([100, 100, 100]);

        translate([0, th, th])
        difference() {
            translate([0, (10+th)/2-th, 80/2-th])
                cube([64+2*th, 10+th, 80], center=true);
            translate([0, nozzle_d, 80/2+17.5]) {
                linear_extrude(80, center=true) {
                    offset(r=nozzle_d, $fs=nozzle_d/2)
                        polygon(slope_profile);
                }
            }

            translate([0, (4+2*nozzle_d)/2, 80/2+0])
                cube([48+nozzle_d, 4+2*nozzle_d, 80], center=true);
            translate([0, 4+nozzle_d + (6+nozzle_d)/2, 80/2+2.5])
                cube([48+nozzle_d, 6+th, 80], center=true);
        }
    }
}

velebon_qb_6rl();
//velabon_mount();
