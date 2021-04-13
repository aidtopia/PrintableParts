xhat = [1, 0, 0];
yhat = [0, 1, 0];
zhat = [0, 0, 1];

// `tt_shaft` matches the shafts of the "TT" toy gear motors.
// For a snug fit, set `clearance` to 0.3 when using to bore a
// matching hole.
module tt_shaft(h=1, clearance=0.0) {
    // These dimensions come from the diagram on the Adafruit site
    // and were confirmed with calipers.
    // https://www.adafruit.com/product/3777
    shaft_d = 5.4 + clearance;
    shaft_w = 3.7 + clearance;

    // The shaft is a cylinder flattened on opposite sides.  
    intersection() {
      cylinder(d=shaft_d, h=h, $fn=45);
      translate(h/2*zhat) cube([shaft_w, shaft_d, h], center=true);
    }
}

module tt_shaft_envelope(h=1, clearance=0.0) {
    shaft_d = 5.4 + clearance;
    cylinder(d=shaft_d, h=h, $fn=45);
}

module tt_shaft_bored(h=1) {
    bore_d = 2;  // rounded up for 1.95 mm on diagram
    difference() {
        tt_shaft(h=h);
        translate([0, 0, -1]) cylinder(d=bore_d, h=h+2, $fn=16);
    }
}

module link(units=5, unit_size=12.7) {
    bar_th = unit_size/4;
    pin_d = unit_size/4;
    pin_h = bar_th;
    
    module bar() {
        bar_w = unit_size - pin_d;
        hull() {
            cylinder(d=bar_w, h=bar_th);
            translate((units - 1) * unit_size * xhat)
                cylinder(d=bar_w, h=bar_th);
        }
    }
    
    module pin() {
        shaft_h = bar_th + pin_h;
        tt_shaft(h=shaft_h, clearance=0);
    }
    
    module pinhole() {
        shaft_h = bar_th + pin_h;
        translate(-1*zhat) cylinder(d=2, h=shaft_h + 2, $fn=16);
    }
    
    module bearing() {
        translate(-1*zhat) tt_shaft_envelope(h=bar_th + 2, clearance=0.4);
    }
    
    module slot() {
        translate(-1*zhat) tt_shaft(bar_th + 2, clearance=0.3);
    }
    
    difference() {
        union() {
            bar();
            pin($fn=48);
        }
        pinhole();
        if (units > 2) {
            for (i = [1:units-2]) {
                translate(i*unit_size*xhat) bearing();
            }
        }
        if (units > 1) {
            translate((units-1)*unit_size*xhat) slot();
        }
    }
}

unit_size=12.7;
longest=5;
for (i = [1:longest]) {
    translate(i*(unit_size+1)*yhat) union() {
        link(i, unit_size=unit_size);
        if (i < longest) {
            translate(i*unit_size*xhat) link(longest-i, unit_size=unit_size);
        }
    }
}

tt_shaft_bored(h=8);

translate(10*xhat + 3.7/2*zhat) rotate(90*yhat) tt_shaft(h=20);

