// Cat Litter Box Scooper Holder
// Adrian McCarthy 2023

module scooper_holder() {
    height = 130;
    width = 142;
    depth = 50;
    th = 2;
    taper = [1.2, 1.4];

    module pattern() {
        square([width, depth], center=true);
    }

    module footprint() {
        square([taper.x*(width+2*th)+th, taper.y*(depth+2*th)+2*th],
            center=true);
    }

    module plinth() {
        linear_extrude(th)
            offset(th, $fn=30) scale(taper) pattern();
        translate([0, 0, th]) {
            linear_extrude(6*th, scale=[1/taper.x, 1/taper.y]) {
                offset(th, $fn=30) scale(taper) pattern();
            }
        }
    }
    
    module shell(hollow=true) {
        linear_extrude(height, scale=taper, convexity=6) {
            difference() {
                offset(th/2, $fn=30) pattern();
                if (hollow) pattern();
            }
        }
    }
    
    difference() {
        union() {
            difference() {
                plinth();
                translate([0, 0, th]) shell(hollow=false);
            }
            translate([0, 0, th]) shell();
        }

        translate([0, 0, 170]) rotate([90, 0, 0]) {
            linear_extrude(taper.y*depth/2 + 2*th) {
                circle(d=150, $fn=90);
            }
        }
    }
}

scooper_holder();