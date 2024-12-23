// PVC pipe connectors for Tinker Toy-like construction.
// Inspired, in part, by Slant3D: https://www.youtube.com/watch?v=csUGcIPNNkk

use <aidslant.scad>

function inch(inches) = 25.4 * inches;

module clip_negative_z() {
    difference() {
        children();
        translate([0, 0, -1000]) {
            linear_extrude(1000, convexity=8) {
                square(1000, center=true);
            }
        }
    }
}

// Creates a linear fillet of radius `r` and length `l` that fits into a
// crevice along the intersection of two surfaces with normal vectors given
// by `normal1` and `normal2`.
module fillet(
    r=1, l=1,
    normal1=[0, 1, 0], normal2=[1, 0, 0],
    direction=[0, 0, 0],
    center=false,
    nozzle_d=0.4
) {
    assert(len(normal1) == 3 && norm(normal1) > 0);
    norm1 = normal1/norm(normal1);
    assert(len(normal2) == 3 && norm(normal2) > 0);
    norm2 = normal2/norm(normal2);
    assert(len(direction) == 3);
    axis = norm(direction) == 0 ? cross(norm2, norm1)
                                : direction/norm(direction);

    angle = acos(norm1 * norm2);
    assert(0 < angle && angle <= 90);
    triangle = [ [-0.0001, -0.0001], [r*cos(angle), r*sin(angle)], [r, -0.0001] ];
    c0 = triangle[1] + triangle[2];

    linear_extrude(l, center=center) {
        difference() {
            polygon(triangle);
            translate(c0) circle(r=r, $fs=nozzle_d/2);
        }
    }
}

module PVC_corner(od, l=inch(1.25), wall_th=3, nozzle_d=0.4) {
    module sleeve(l, nozzle_d=nozzle_d) {
        $fs = nozzle_d/2;
        difference() {
            linear_extrude(l, convexity=6) {
                difference() {
                    $fa=6;
                    offset(delta=wall_th) square(od, center=true);
                    offset(nozzle_d/2) circle(d=od);
                }
            }
            translate([0, 0, l-1]) {
                cylinder(h=2, d1=od+nozzle_d, d2=od+nozzle_d+3);
            }
            // Chamfer off the sharp points at the corners.
            cut = 2*wall_th;
            r = sqrt(2*(od/2 + wall_th)*(od/2 + wall_th));
            for (theta=[45:90:360])
                rotate([0, 0, theta])
                    translate([r, 0, sleeve_l])
                        rotate([0, atan(sqrt(2)), 0])
                            cube([2*cut, 2*cut, cut], center=true);
        }
    }
    
    module countersunk_screw_hole(depth, nozzle_d=nozzle_d) {
        head_r  = head_d/2;
        shaft_r = shaft_d/2;
        nudge   = nozzle_d/2;  // for printing tolerance
        points = [
            [0,             1],
            [head_r+nudge,  1],
            [head_r+nudge,  0],
            [shaft_r+nudge, -head_h],
            [shaft_r+nudge, -depth],
            [inch(0),       -depth]
        ];
        rotate_extrude($fs=nozzle_d/2) polygon(points);
    }

    module sleeve_with_screw(l, nozzle_d=nozzle_d) {
        difference() {
            union() {
                sleeve(l, nozzle_d=nozzle_d);
                translate([sleeve_w/2, 0, screw_dl])
                    rotate([0, 90, 0])
                        cylinder(h=boss_h, d1=boss_d1, d2=boss_d2);
                translate([0, sleeve_w/2, screw_dl])
                    rotate([-90, 0, 0])
                        cylinder(h=boss_h, d1=boss_d1, d2=boss_d2);
            }
            translate([sleeve_w/2 + boss_h, 0, screw_dl])
                rotate([0, 90, 0])
                    countersunk_screw_hole(wall_th + boss_h, nozzle_d);
            translate([0, sleeve_w/2 + boss_h, screw_dl])
                rotate([-90, 0, 0])
                    countersunk_screw_hole(wall_th + boss_h, nozzle_d);
        }
    }
    
    module tab(nozzle_d=nozzle_d) {
        translate([0, 0, -sleeve_w/2]) {
            difference() {
                union() {
                    linear_extrude(wall_th) {
                        hull() {
                            #polygon([
                                [sleeve_w/2-0.0001, sleeve_w/2],
                                [sleeve_w/2-0.0001, screw_dl],
                                [screw_dl, sleeve_w/2-0.0001]
                            ]);
                            translate([sleeve_w, sleeve_w]) circle(boss_d2);
                        }
                    }
                    translate([sleeve_w, sleeve_w, wall_th]) {
                        cylinder(h=boss_h, d1=boss_d1, d2=boss_d2);
                    }
                }
                translate([sleeve_w, sleeve_w, wall_th + boss_h]) {
                    countersunk_screw_hole(wall_th + boss_h + 1, nozzle_d);
                }
            }
        }
    }

    sleeve_w = od + 2*wall_th;
    echo(sleeve_w/25.4);
    sleeve_l = l + sleeve_w;
    screw_dl = sleeve_w + l/2;

    // For typical #6 flat head wood screw.
    head_h  = inch(0.083);
    head_d  = inch(0.244);
    shaft_d = inch(0.138);

    boss_d1 = 3*(head_d+nozzle_d);
    boss_d2 = 1.5*(head_d+nozzle_d);
    boss_h  = 2*head_h;

    clip_negative_z()
    translate([0, 0, -1/3*sqrt(3*sleeve_w*sleeve_w)])
    slant3d()
    translate([sleeve_w/2, sleeve_w/2, sleeve_w/2])
    union() {
        // A cube where all the axes come together.
        cube(sleeve_w, center=true);

        // A sleeve along each major axis.
        sleeve_with_screw(sleeve_l);
        rotate([0, 90, 0]) rotate([0, 0, 90]) sleeve_with_screw(sleeve_l);
        rotate([-90, 0, 0]) rotate([0, 0, -90]) sleeve_with_screw(sleeve_l);

        // Fillets for strong/attractive joints.
        translate([sleeve_w/2, sleeve_w/2, 0])
            fillet(r=3, l=sleeve_w, center=true);
        translate([sleeve_w/2, 0, sleeve_w/2]) rotate([90, 0, 0])
            fillet(r=3, l=sleeve_w, center=true);
        translate([0, sleeve_w/2, sleeve_w/2]) rotate([90, 0, 90])
            fillet(r=3, l=sleeve_w, center=true);
        translate([sleeve_w/2, sleeve_w/2, sleeve_w/2])
            intersection() {
                fillet(r=3, l=sleeve_w, center=true);
                rotate([90, 0, 0])
                fillet(r=3, l=sleeve_w, center=true);
                rotate([90, 0, 90])
                fillet(r=3, l=sleeve_w, center=true);
            }

        // Tabs for mounting
        tab(nozzle_d);
        rotate([0, 90, 0]) rotate([0, 0, 90]) tab(nozzle_d);
        rotate([-90, 0, 0]) rotate([0, 0, -90]) tab(nozzle_d);
    }
}

// 3/4-inch (trade size) schedule 40 PVC pipe with the wall thickness
// chosen to make the sleeve width 1.25".
PVC_corner(26.7, wall_th=2.525);
