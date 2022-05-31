// Cat Grass Planter
// Adrian McCarthy
// 2022-05-28

// Set to 0 to preview the parts assembled or to a higher value to see an exploded parts diagram.
Explode = 0; // [0:1:100]

module __End_of_Customizers() {}

xhat = [1, 0, 0];
yhat = [0, 1, 0];
zhat = [0, 0, 1];

module explode(distance, direction=zhat) {
    factor = ($preview && $children > 1) ? Explode/100 : 0;
    if (factor == 0) {
        children();
    } else {
        for (i = [0:$children-1]) {
            amount = i*factor*distance;
            translate(amount*direction) children(i);
            echo(str("explode(", distance, ") child ", i, " moved ", amount));
        }
    }
}

module cross_section(plane="xz", keep=false, cut_size=250, center=false) {
    if (plane == "" || plane == "none") {
        children();
    } else {
        d = keep ? cut_size/2 : 0;
        shift_pos = center ?  d/2 : 0;
        shift_neg = center ? -d/2 : -d;
        v = plane == "xy" ? zhat :
            plane == "xz" ? yhat :
                            xhat;

        translate(shift_pos * v) difference() {
            union() { children(); }
            translate(-cut_size/2 * v) cube(cut_size, center=true);
        }
        if (keep) {
            translate(shift_neg * v) difference() {
                union() { children(); }
                translate(cut_size/2 * v) cube(cut_size, center=true);
            }
        }
    }
}

module cat_grass_planter(wall_th=3, perf_d=1.5, nozzle_d=0.4) {
    days = [
        "SUNDAY",
        "MONDAY",
        "TUESDAY",
        "WEDNESDAY",
        "THURSDAY",
        "FRIDAY",
        "CATURDAY!"
    ];

    sides = len(days);

    soil_volume = 325000;  // expanded volume (mm^3) of one soil puck
    soil_depth = 40;

    soil_area = soil_volume / soil_depth;
    soil_d = sqrt(8 * soil_area / (sides * sin(360 / sides)));
    echo(str("soil box \"diameter\" = ", soil_d));
    water_d = soil_d + 2*wall_th + 2;
    h = soil_depth;
    riser_h = h/2;
    tube_id = 6;
    tube_h = h + 2*wall_th;

    function volume(diameter, number_of_sides, height) =
        let (n = number_of_sides, r = diameter/2)
            n*r*r/2 * sin(360/n) * height;

    function effective_r(diameter) =
        let (interior_angle = (sides - 2)*180 / sides)
            diameter/2 * sin(interior_angle/2);

    module footprint(d) { circle(d=d, $fn=sides); }
    module riser(h) { cylinder(h=h, r=3, $fs=nozzle_d/2); }
    
    module water_box(id, h, riser_h) {
        od = id + 2*wall_th;
        dtheta = 360/sides;
        difference() {
            union() {
                // outer walls
                linear_extrude(h + wall_th, convexity=10) difference() {
                    footprint(od);
                    footprint(id);
                }
                
                // short interior walls to support soil box
                linear_extrude(riser_h, convexity=10) difference() {
                    footprint(od);
                    footprint(id-(2*wall_th + 1));
                }
                

                // bottom
                linear_extrude(wall_th) footprint(od);
            }
            
            // labels
            text_size = od*5/100;
            interior_angle = (sides - 2)*180 / sides;
            r = effective_r(od);
            for (i = [0:sides - 1]) {
                rotate([0, 0, (i+0.5)*dtheta])
                    translate([r, 0, h/2])
                        rotate(90*zhat) rotate(45*yhat) rotate(90*xhat)
                            linear_extrude(wall_th, center=true, convexity=10)
                                text(days[i], size=text_size,
                                     halign="center", valign="center");
            }
        }

        translate([0, 0, wall_th]) {
            // risers
            for (i = [1:sides])
                rotate([0, 0, (i+0.5)*dtheta])
                    translate([id/4, 0, 0]) riser(riser_h);
        }
    }
    
    module soil_box(id, h) {
        od = id + 2*wall_th;
        tube_od = tube_id + wall_th;
        difference() {
            union() {
                linear_extrude(h + wall_th) {
                    difference() {
                        footprint(od);
                        footprint(id);
                    }
                    
                    // Fill tube.
                    translate((id-tube_od)/2*xhat)
                        circle(d=tube_od, $fs=nozzle_d/2);
                }

                // Funnel.
                translate((h+wall_th)*zhat)
                    translate((id-tube_od)/2*xhat)
                        linear_extrude(tube_od, convexity=10, scale=2)
                            difference() {
                                circle(d=tube_od, $fs=nozzle_d/2);
                                circle(d=tube_id, $fs=nozzle_d/2);
                            }


                linear_extrude(wall_th) difference() {
                    footprint(id);
                    
                    // These perforations are for aeration.
                    r = effective_r(id) - perf_d;
                    for (y = [-id/2:5:id/2]) {
                        for (x = [-id/2:5:id/2]) {
                            if (norm([x, y]) < r) {
                                translate([x, y, 0]) circle(d=perf_d, $fn=8);
                            }
                        }
                    }
                    
                    // These larger holes are for wicking material
                    // to draw the water from below the air gap
                    // into the soil.
                    for (theta = [60:90:360])
                        rotate(theta*zhat) translate(od/3*xhat)
                            circle(d=6, $fs=0.2);                    
                }
            }

            // The fill tube passes the water down past the soil to
            // the reservoir.
            translate((id-tube_od)/2*xhat)
                translate(-zhat) linear_extrude(tube_h+2, convexity=10)
                    circle(d=tube_id, $fs=nozzle_d/2);
        }
    }
    
    if ($preview) {
        cross_section(plane="none") explode(2*h, zhat) {
            water_box(water_d, h, riser_h);
            translate((wall_th + riser_h)*zhat)
                color("orange") soil_box(soil_d, h);
        }
    } else {
        translate(-0.51*water_d*xhat) water_box(water_d, h, riser_h);
        translate(0.51*soil_d*xhat) soil_box(soil_d, h);
    }
    echo(str("soil volume = ", volume(soil_d, sides, h)));
}

cat_grass_planter(wall_th=2);
