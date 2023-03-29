// End Cap for 2020 T-Slot Aluminum Extrusion
// Adrian McCarthy 2023-03-29

// Extrusion profiles vary in many ways.  Values were based on ones
// commonly seen in dimension diagrams online, and tweaked for the
// extrusion I had on hand to make a good friction fit.

module end_cap_2020(h=1, r=1, nozzle_d=0.4) {
    reach = 10 - r;
    linear_extrude(h) hull($fs=nozzle_d/2) {
        translate([-reach, -reach]) circle(r=r);
        translate([ reach, -reach]) circle(r=r);
        translate([ reach,  reach]) circle(r=r);
        translate([-reach,  reach]) circle(r=r);
    }
    
    a = 6/2;
    b = 16.4/2;
    c = 10/2;
    d = 14/2;
    t_profile = [
        [ 10,   a],
        [  b,   a],
        [  b,   c],
        [  d,   c],
        [  d,  -c],
        [  b,  -c],
        [  b,  -a],
        [ 10,  -a]
    ];
    linear_extrude(6) {
        for (theta = [0:90:270]) {
            rotate([0, 0, theta]) polygon(t_profile);
        }
    }
}

end_cap_2020();
