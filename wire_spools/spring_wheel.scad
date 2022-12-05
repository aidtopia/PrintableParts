// Adrian McCarthy
// Experimenting with compliant shapes to make springs and such
// 2020-05-18

use <aidgear.scad>

module spiral(r1=1, r2=10, degrees=360, th=1) {
    // mr1 and mr2 are the modified radii, adjusted to account
    // for the thickness of the spring.  We guarantee that mr1
    // is the smaller of the two.
    mr1 = max(0, min(r1, r2) - th/2);
    mr2 = max(r1, r2) + th/2;
    delta_r = mr2 - mr1;
    avg_r = mr1 + delta_r/2;
    step_a = ($fa > 0) ? ($fa/degrees) : 1;
    step_s = ($fs > 0) ? 360 / degrees * $fs / (2*PI*avg_r) : 1;
    step = ($fn > 0) ? 1/$fn : min(step_a, step_s);
    inners = [
        for (i = [0:step:1])
            let (theta = i*degrees, r = mr1 + i*delta_r - th/2)
              [r*cos(theta), r*sin(theta)]
    ];
    outers = [
        for (i = [1:-step:0])
            let (theta = i*degrees, r = mr1 + i*delta_r + th/2)
              [r*cos(theta), r*sin(theta)]
    ];

    polygon([each inners, each outers]);
}

module spring_wheel(h=10, spring_th=1, arms=2, center=false) {
    linear_extrude(h, center=center) {
        for (arm = [0:arms-1])
            rotate([0, 0, arm*360/arms])
                spiral(2, 13, 360*2, th=spring_th);
        difference() { circle(r=15); circle(r=13); }
        circle(r=2);
    }
    linear_extrude(h+10, center=center) circle(r=2, $fn=6);
//    translate([0, 0, h+10]) rotate([90, 0, 0]) linear_extrude(2, center=true) circle(d=14, $fn=6);
}

// I thought I came up with this on my own (after making the
// spring_wheel), but it's possible I was subconsciously inspired
// by images of spring loaded gears online.  I've since watched a
// video by YouTuber SunShine, who dubbed it a "SunShine gear".
// https://youtu.be/IrT1DaSBeQ4
module spring_gear(h=10, r=13, spring_th=1, arms=2, center=false) {
    g = AG_define_gear(16, iso_module=1, pressure_angle=21, name="spring gear");
    AG_echo(g);
    od = AG_outer_diameter(g);
    id = AG_inner_diameter(g) - 1.6;
    linear_extrude(h, center=center) {
        difference() {
            polygon(AG_tooth_profile(g));
            circle(d=id, $fs=0.2);
        }
        for (arm = [0:arms-1])
            rotate([0, 0, arm*360/arms])
                spiral(1, id/2, 360*2, th=spring_th);
    }
}

module spring_back_slider() {
    module slider(w=12, h=3, l=30, clearance=0) {
        translate([0, 3, 0]) rotate([90, 0, 0])
        linear_extrude(l+clearance, center=true)
            offset(clearance)
            polygon([[-w/2+h, 0], [-w/2, h],
                     [0, (w+h)/2],
                     [w/2, h], [w/2-h, 0]]);
    }

    module frame() {
        difference() {
            translate([-26, -10, 0]) cube([52, 20, 10]);
            slider(clearance=0.4);
            translate([ 15, 0, -1]) cylinder(h=8, r=9+0.4+0.1);
            translate([-15, 0, -1]) cylinder(h=8, r=9+0.4+0.1);
        }
    }
    
    module spring() {
        translate([15, 0, 0]) {
            spring_gear(h=3, r=5.5, spring_th=0.8, arms=2, $fs=0.2); 
            translate([0, 0, 3]) cylinder(h=5, r1=2, r2=8.5);
            cylinder(h=4, r=2+0.8/2, $fs=0.2);
        }
    }

    frame();
    slider();
    spring();
    mirror([1, 0, 0]) spring();
}

module rack_test() {
    gear = AG_define_gear(11);
    rack = AG_define_rack(8);
    od = AG_outer_diameter(gear);
    id = AG_root_diameter(gear) - 1.6;
    mesh_dist = AG_center_distance(gear, rack);
    hub_r = AG_module(gear);
    peg_s = 2*hub_r;

    module spring_gear() {
        linear_extrude(3, convexity=10) {
            difference() {
                polygon(AG_tooth_profile(gear));
                circle(d=id, $fs=0.2);
            }

            circle(r=hub_r, $fs=0.2);
            arms = 3;
            for (i = [1:arms]) {
                rotate([0, 0, i*360/arms])
                    spiral(r1=hub_r, r2=id/2, th=0.8, degrees=360,
                           $fs=0.2);
            }
        }
        translate([0, 0, 2.8]) linear_extrude(2.2) square(peg_s, center=true);
    }

    module slider() {
        linear_extrude(3, convexity=10)
            polygon(AG_tooth_profile(rack));
    }
    
    module base() {
        linear_extrude(2) difference() {
            square([2*od, od], center=true);
            translate([-(mesh_dist), 0]) square(peg_s + 0.2, center=true);
        }
        color("blue") translate([AG_backing(rack) + 0.2, -od/2, 2]) {
            cube([4, od, 4]);
            translate([-1, 0, 3.2]) cube([5, od, 1]);
        }
    }
    
    if ($preview) {
        color("green") translate([-(mesh_dist), 0, 3]) rotate([0, 180, 0]) spring_gear();
        color("yellow") translate([0, -3*AG_circular_pitch(rack)/2, 0]) rotate([0, 0, 90]) slider();
        translate([0, 0, -2]) base();
    } else {
        translate([3*od/2+1, 0, 0]) spring_gear();
        translate([-od/2, 3*od/4, 0]) slider();
        base();
    }
}

//spring_wheel(h=4, spring_th=0.8, arms=3, $fa=1);

//translate([40, 0, 2])
//spring_back_slider();

rack_test();