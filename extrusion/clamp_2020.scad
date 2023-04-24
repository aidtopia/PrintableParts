function inch(x) = 25.4*x;

module extrusion_clamp(nozzle_d=0.4) {
    th = 5;
    gap = 2;
    difference() {
        linear_extrude(25, center=true, convexity=10) {
            difference() {
                union() {
                    square([20+2*th, 20+2*th], center=true);
                    square([30+th, 10+th]);
                }
                square([20+nozzle_d, 20+nozzle_d], center=true);
                translate([0, (20-nozzle_d)/2-gap]) square([30+th, gap+nozzle_d]);
            }
            union() {
                delta = 10+nozzle_d/2;
                translate([-delta,   0]) circle(d=6, $fs=nozzle_d/2);
                translate([ delta,   0]) circle(d=6, $fs=nozzle_d/2);
                translate([  0, -delta]) circle(d=6, $fs=nozzle_d/2);
                translate([  0,  delta]) circle(d=6, $fs=nozzle_d/2);
            }
        }
        rotate([-90, 0, 0])
            translate([20+th, 0, -0.1]) {
                cylinder(h=10+th+0.2, d=inch(1/4)+nozzle_d, $fs=nozzle_d/2);
                rotate([0, 0, 30]) cylinder(h=inch(7/32), d=(inch(7/16)+nozzle_d)/cos(30), $fn=6);
            }
    }
}

module extrusion_camclamp(cusp_angle=15, nozzle_d=0.4) {
    th = 5;
    cam_offset = 8;
    outer_w = th + 20 + th;
    outer_l = th + 20 + 2*cam_offset;
    inner_w = 20 + nozzle_d;
    inner_l = inner_w;
    h = max(inner_w, 2*cam_offset);

    m4_close_d = 4.3;
    m4_head_d  = 8.0;
    m4_head_h  = 3.1;
    m4_insert_d = 5.6;
    m4_insert_l = 4.7;
    
    module frame() {
        difference() {
            linear_extrude(h, center=true, convexity=10) {
                difference() {
                    translate([0, (outer_w - outer_l)/2])
                        square([outer_w, outer_l], center=true);
                    translate([0, 0])
                        square([inner_w, inner_l], center=true);
                    translate([0, -(inner_l+2*cam_offset)/2])
                        square([inner_w, 2*cam_offset + 0.1], center=true);
                }
                union() {
                    delta = 10+nozzle_d/2;
                    translate([ delta,   0]) circle(d=6, $fs=nozzle_d/2);
                    translate([-delta,   0]) circle(d=6, $fs=nozzle_d/2);
                    translate([  0,  delta]) circle(d=6, $fs=nozzle_d/2);
                }
            }
            translate([0, -(20/2 + cam_offset), 0]) rotate([0, 90, 0]) {
                cylinder(h=outer_w+0.1, d=m4_close_d+nozzle_d, center=true, $fs=nozzle_d/2);
                translate([0, 0, (outer_w+0.1-m4_head_h)/2])
                    cylinder(h=m4_head_h+0.1, d=m4_head_d+nozzle_d, center=true, $fs=nozzle_d/2);
                translate([0, 0, -(outer_w+0.1-m4_insert_l)/2])
                    cylinder(h=m4_insert_l+1+0.1, d=m4_insert_d+nozzle_d, center=true, $fs=nozzle_d/2);
            }
        }
    }
    
    module cam() {
        lever_l = h + 5;
        nom_r = cam_offset + 3*nozzle_d;
        min_r = cam_offset - 4*nozzle_d;
        max_r = nom_r/cos(cusp_angle);
        cam_profile = [
            for (theta=[0:2:360])
                let(r = (320 < theta || theta <= cusp_angle) ? nom_r/cos(theta) :
                        (cusp_angle < theta && theta <= 180) ? max_r + (min_r - max_r)*(theta-cusp_angle)/(180-cusp_angle) :
                        min_r)
                [r*cos(theta), r*sin(theta)]
        ];
        linear_extrude(inner_w - nozzle_d, convexity=10) {
            difference() {
                union() {
                    polygon(cam_profile);
                    translate([-min_r, -lever_l]) square([th, lever_l]);
                }
                circle(d=m4_close_d+nozzle_d, $fs=nozzle_d/2);
            }
        }
    }
    
    translate([0, 0, h/2]) frame();
    translate([0, -20, 0]) rotate([0, 0, 180]) cam();
}

extrusion_camclamp();
