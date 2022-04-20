module hexblock(cell_size=12, rows=6, cols=7, nozzle_d=0.4) {
    hex = cell_size;
    peg = hex - nozzle_d;
    dx = cell_size * cos(30);
    dy = cell_size;
    ex = cell_size - dx;
    width = ex + dx*cols + ex;
    length = dy*rows;

    linear_extrude(cell_size)
    difference() {
        square([width, length]);
        translate([ex, 0, 0]) {
            for (c = [0:2:cols-1]) {
                translate([dx*(c + 0.5), 0, 0])
                for (r = [0:rows-1]) {
                    translate([0, dy*(r + 0.5), 0]) circle(d=hex, $fn=6);
                }
            }
            for (c = [1:2:cols-1]) {
                translate([dx*(c + 0.5), 0, 0])
                for (r = [0:rows-2]) {
                    translate([0, dy*(r + 1), 0]) circle(d=hex, $fn=6);
                }
            }
        }
    }

    translate([ex, 0, 0]) {
        for (c = [0:2:cols-1])
            translate([dx*(c + 0.5), 0, peg*cos(30)/2])
                rotate([90, 0, 0])
                    cylinder(d=peg, h=cell_size, $fn=6);
    }
}

translate([0, 0, -0.2]) rotate([90, 0, 0]) color("green") hexblock(15);
hexblock(15);