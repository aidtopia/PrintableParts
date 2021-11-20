// Cone holder (for ice cream cones, snow cones, etc.)
// Adrian McCarthy 2021

module snowflake() {
    for (theta = [0:60:300]) {
        rotate([0, 0, theta]) {
            children();
            scale([1, -1]) children();
        }
    }
}

// Based on the dimensions of a 6-ounce Sno-Kone(R) brand paper cone.
module cone_6_ounce() {
    hull() {
        translate([0, 0, 110]) linear_extrude(1) circle(d=85, $fs=0.4);
        translate([0, 0, 2]) sphere(d=4, $fs=0.2);
    }
}

module plain_cone_holder() {
    height = 67;
    top_id = 50;
    bottom_od = 70;
    thickness = 2.8;
    top_od = top_id + 2*thickness;
    bottom_id = bottom_od - 2*thickness;

    difference() {
        cylinder(h=height, d1=bottom_od, d2=top_od, $fn=120);
        translate([0, 0, -0.1]) cylinder(h=height+0.2, d1=bottom_id, d2=top_id, $fn=120);
    }
}

module cone_holder() {
    difference() {
        plain_cone_holder();
        rotate([0, 0, 57]) translate([0, 0, 20]) rotate([90]) linear_extrude(height=100, center=true) rotate([0, 0, 20]) scale(13) children();
        rotate([0, 0, 7]) translate([0, 0, 33]) rotate([90]) linear_extrude(height=100, center=true) rotate([0, 0, 9]) scale(10) children();
        rotate([0, 0, 37]) translate([0, 0, 50]) rotate([90]) linear_extrude(height=100, center=true) rotate([0, 0, -15]) scale(7) children();
    }
}

if ($preview) {
    #translate([0, 0, 2.5]) cone_6_ounce();
}

cone_holder() {
    snowflake($fn=9) {
        long = 1;
        short = long/sqrt(3);
        circle(r=short/3);
        translate([long/3, 0]) circle(r=short/8);
        translate([2*long/3, 0]) circle(r=short/6);
        translate([long, 0]) circle(r=short/4);
        translate([long/2, short/6]) circle(r=short/10);
        translate([long/2.5, short/2.5]) circle(r=short/10);
    }
}    
