module c_ring(h=10, id=20, th=1.8, opening=90, nozzle_d=0.4) {
    od = id + 2*th;

    r = od/2 + th;
    wedge_points = [
        [0, 0],
        [r*cos(opening/2), r*sin(opening/2)],
        [r, 0],
        [r*cos(-opening/2), r*sin(-opening/2)]
    ];

    linear_extrude(h, convexity=4) {
        difference() {
            circle(d=od, $fn=48);
            circle(d=id, $fn=48);
            polygon(wedge_points);
        }
        
        for (theta = [-opening/2:opening:opening]) {
            rotate([0, 0, theta])
                translate([(id/2+od/2)/2, 0, 0])
                    circle(d=th, $fn=16);
        }
    }
}

// This part should snap onto the pipes of the Manfrotto Magic Arm.
translate([(20+1.8)/2, 0, 0])
    c_ring(h=10, id=20, th=1.8, opening=75);

rotate([0, 0, 180]) translate([(5+1.8)/2, 0, 0])
    c_ring(h=5, id=5, th=1, opening=45);
