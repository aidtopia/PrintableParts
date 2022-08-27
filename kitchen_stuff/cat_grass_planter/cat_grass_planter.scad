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

module cross_section(plane="xy", keep=false, cut_size=250, center=false) {
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
        "CATURDAY!",
        ""
    ];

    sides = len(days);

    soil_volume = 380000;  // expanded volume (mm^3) of one soil puck
    soil_depth = 44;

    soil_area = soil_volume / soil_depth;
    soil_id = sqrt(8 * soil_area / (sides * sin(360 / sides)));
    soil_od = soil_id + 2*wall_th;
    soil_h = soil_depth + 5;

    water_id = soil_od + nozzle_d;
    water_od = water_id + 2*wall_th;
    water_h = 40;
    riser_h = 0.6*water_h;

    tube_id = 12;
    tube_od = tube_id + wall_th;
    tube_h = soil_h + 12;
    
    lid_od = soil_od;
    lid_id = lid_od - 2*wall_th - nozzle_d;

    function volume(diameter, number_of_sides, height) =
        let (n = number_of_sides, r = diameter/2)
            n*r*r/2 * sin(360/n) * height;

    function effective_r(diameter) =
        let (interior_angle = (sides - 2)*180 / sides)
            diameter/2 * sin(interior_angle/2);

    module footprint(d) { circle(d=d, $fn=sides); }
    
    module water_box() {
        id = water_id;
        od = water_od;

        dtheta = 360/sides;
        difference() {
            union() {
                // outer walls
                linear_extrude(water_h+wall_th, convexity=10) difference() {
                    footprint(od);
                    footprint(id);
                }
                
                // short interior walls to support soil box
                linear_extrude(riser_h+wall_th, convexity=10) difference() {
                    footprint(od);
                    footprint(id-(3*wall_th + 1));
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
                    translate([r, 0, water_h/2])
                        rotate(90*zhat) rotate(45*yhat) rotate(90*xhat)
                            linear_extrude(wall_th, center=true, convexity=10)
                                text(days[i], size=text_size,
                                     halign="center", valign="center");
            }
        }

        // risers
        translate(wall_th*zhat)
            for (i = [1:2:sides])
                rotate([0, 0, i*dtheta])
                    translate([id/2 - id/4, -wall_th/2, 0])
                        cube([id/4, wall_th, riser_h]);
    }
    
    module soil_box() {
        id = soil_id;
        od = soil_od;
        difference() {
            union() {
                linear_extrude(soil_h + wall_th, convexity=10) {
                    // walls
                    difference() {
                        footprint(od);
                        footprint(id);
                    }
                }
                
                // fill tube
                translate((id-tube_id)/2*xhat) {
                    linear_extrude(tube_h, convexity=10) {
                            circle(d=tube_od, $fs=nozzle_d/2);
                    }

                    // funnel
                    translate(tube_h*zhat)
                        linear_extrude(tube_od, convexity=10, scale=2.8)
                            difference() {
                                circle(d=tube_od, $fs=nozzle_d/2);
                                circle(d=tube_id, $fs=nozzle_d/2);
                            }
                }

                // bottom
                linear_extrude(wall_th) difference() {
                    footprint(id);
                    
                    // These perforations are for aeration.
                    r = effective_r(id) - perf_d;
                    for (y = [-id/2:5:id/2]) {
                        for (x = [-id/2:5:id/2]) {
                            if (norm([x, y]) < r) {
                                translate([x, y, 0])
                                    square(perf_d, center=true);
                            }
                        }
                    }
                    
                    // These larger holes are for wicking material
                    // to draw the water from below the air gap
                    // into the soil.  A rolled up bit of paper towel
                    // works well.
                    for (theta = [60:90:360])
                        rotate(theta*zhat) translate(od/3*xhat)
                            circle(d=8, $fs=0.2);                    
                }
            }

            // The fill tube passes the water down past the soil to
            // the reservoir.  Here's where we bore it through.
            translate((id-tube_id)/2*xhat)
                translate(-zhat) linear_extrude(tube_h+2, convexity=10)
                    circle(d=tube_id, $fs=nozzle_d/2);
        }
    }
    
    module lid() {
        perf_d = 10;
        perf_spacing = perf_d + 2*nozzle_d;
        tube_notch = tube_od + 2*nozzle_d;
        difference() {
            union() {
                linear_extrude(wall_th, convexity=10)
                    footprint(lid_od);
                translate(-wall_th*zhat) {
                    linear_extrude(wall_th, convexity=10) difference() {
                        footprint(lid_id);
                        offset(delta=-wall_th) footprint(lid_id);
                    }
                    
                    
                    linear_extrude(wall_th, convexity=10)
                        intersection() {
                            translate([(lid_id - tube_id)/2, 0, 0])circle(d=tube_notch+2*wall_th);
                            footprint(lid_id);
                        }
                }
            }
            
            translate([(lid_id - tube_id)/2, 0, -wall_th-1])
                linear_extrude(2*wall_th+2, convexity=10) {
                    circle(d=tube_notch);
                    translate(-tube_notch/2*yhat)
                        square(tube_notch);
                }

            translate([0, 0, -wall_th-1])
            linear_extrude(2*wall_th+2, convexity=10) {
                intersection() {
                    offset(delta=-2*wall_th) footprint(lid_id);
                    union() {
                        for (y = [-lid_id/2:perf_spacing:lid_id/2]) {
                            for (x = [-lid_id/2:perf_spacing:lid_id/2-tube_od]) {
                                translate([x, y, 0])
                                    square(perf_d, center=true);
                            }
                        }
                    }
                }
            }
        }
    }
    
    if ($preview) {
        cross_section(plane="none") explode(2*riser_h, zhat) {
            water_box();
            translate((riser_h + wall_th)*zhat) explode(0.6*soil_h, zhat) {
                color("orange") soil_box();
                color("green") translate((soil_h + wall_th)*zhat) lid();
            }
        }
    } else {
        translate(-0.5*water_od*xhat) rotate([0, 0, 180/sides])
            water_box();
        translate(0.5*soil_od*xhat) rotate([0, 0, 180/sides + 180])
            soil_box();
        translate([0, -0.41*(lid_od+max(water_od, soil_od)), wall_th])
            rotate([180, 0, 180/sides])
                lid();
    }
    echo(str("soil volume = ", volume(soil_id, sides, soil_depth)));
}

cat_grass_planter(wall_th=2);
