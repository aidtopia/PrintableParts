// Decorative snowflakes for holiday lights
// Adrian McCarthy 2021

module snowflake() {
    for (theta = [0:60:300]) {
        rotate([0, 0, theta]) {
            children();
            scale([1, -1]) children();
        }
    }
}

scale(50)
snowflake() {
    square([1, 0.05]);
    translate([1/4, 0]) rotate([0, 0, -30]) square([0.05, 0.2]);
    translate([2/4, 0]) rotate([0, 0, -30]) square([0.05, 0.3]);
    translate([3/4, 0]) rotate([0, 0, -30]) square([0.05, 0.4]);
}
