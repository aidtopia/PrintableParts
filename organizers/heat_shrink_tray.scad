function inch(x) = x * 25.4;
function slice(list, range) = [for (i = range) list[i]];
function sum(values) =
    len(values) == 0 ? 0 :
    len(values) == 1 ? values[0] :
                       values[0] +
                         sum([for (i=[1:len(values)-1]) values[i]]);

module tray(length=inch(6+1/8), widths=[for (i=[0:4]) inch(1)], height=inch(3/4), nozzle_d=0.4) {
    $fs = nozzle_d/2;

    depression_d = inch(2);
    th = 1.2;

    module footprint(width) {
        offset(r=th) square([width, length], center=true);
    }

    module bottom(width) {
        difference() {
            intersection() {
                linear_extrude(height, convexity=6) footprint(width);
                translate([0, 0, th-height]) {
                    translate([0, -length/2, 0]) {
                        rotate([3, 0, 0]) {
                            translate([0, length/2, 0]) {
                                linear_extrude(height) {
                                    square([width, 2*length], center=true);
                                }
                            }
                        }
                    }
                }
            }
            translate([0, length/4, depression_d/2+th])
                rotate([0, 90, 0])
                    cylinder(h=width, d=depression_d, center=true, $fa=4);
        }
    }

    module walls(width) {
        difference() {
            linear_extrude(height, convexity=6) {
                difference() {
                    footprint(width);
                    offset(r=-th) footprint(width);
                }
            }
            translate([0, 0, (width+height)/2])
                rotate([-90, 0, 0])
                    cylinder(h=length, d=width-4*th);
        }
    }
    
    module rail(width) {
        rail_size = inch(3/8);
        translate([0, 0, height-th]) {
            linear_extrude(th, convexity=6) {
                intersection() {
                    footprint(width);
                    translate([0, rail_size/2 - length/2 - th]) {
                        square([th + width + th, rail_size], center=true);
                    }
                }
            }
        }
    }
    
    module unit(width) {
        bottom(width);
        walls(width);
        rail(width);
    }

    offsets = [
        for (i = [0:len(widths)-1])
            i*th + sum(slice(widths, [0:i])) - widths[i]/2
    ];
    echo(widths);
    echo(offsets);

    for (i = [0:len(widths)-1]) {
        translate([offsets[i], 0, 0]) unit(widths[i]);
    }
}

tray(widths=[inch(1), inch(1+1/8), inch(1+1/4), inch(1+3/8), inch(1+1/2)], height=inch(1+1/8));
