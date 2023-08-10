cylinder(d=90, h=2);
linear_extrude(10, convexity=4) difference() {
    circle(d=74, $fn=64);
    circle(d=71, $fn=64);
}
