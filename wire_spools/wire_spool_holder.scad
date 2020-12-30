// Wire Spool Holder
// Adrian McCarthy 2020-12-16

// Goals:
// * parameterized for a variety of spool sizes
// * holds the free end of the wire
// * multiple units can be connected together
// * easy spool changes even when the holder is connected to others
// * easy to see the spool (not hidden in opaque box)
// * able to fit two rows into a 6-qt Sterilite plastic storage container
// * robust enough for electronics bench work without wasting plastic
// * able to print without supports
// * has a place for a label

xhat = [1, 0, 0];
yhat = [0, 1, 0];
zhat = [0, 0, 1];

// A model of a wire spool to help with visualization.
module spool(w, od, id) {
    difference() {
        union() {
            cylinder(d=id+2, h=w, center=true);
            translate(-(w - 1)/2 * zhat) cylinder(d=od, h=1, center=true);
            translate((w - 1)/2 * zhat) cylinder(d=od, h=1, center=true);
        }
        cylinder(d=id, h=w+2, center=true);
    }
}

// A key profile can be extruded to make a key or corresponding slot.
// Another shape could be used, but this wedge shape can be printed without
// supports in any orientation.  This shape does not interlock, but it is
// fine for aligning parts and constraining sliding motion to the extrusion
// direction.
module key_profile(height, width=0, clearance=0, extend=0.01) {
    w = max(width, height);
    y0 = 0;
    y1 = height - clearance/2;
    x1 = (w + clearance/2)/2;
    x0 = max(0, x1 - y1/2);
    
    polygon([
        [ x1, y0 - extend],
        [ x1, y0],
        [ x0, y1],
        [-x0, y1],
        [-x1, y0],
        [-x1, y0 - extend]
    ]);
}

module capsule(d, length=0, clearance=0) {
    dia = d + clearance/2;
    offset = [0, 0, (length ? (length-d)/2 : d)];
    hull() {
        translate(-offset) sphere(d=dia);
        translate( offset) sphere(d=dia);
    }
}

// w, od, and id describe the size of the spool to be held
module spool_holder(wire_d=3, w=22, od=55, id=25.5, wall_th=3, clearance=1) {
    // The spool holder consists of a chassis and a spindle.  The chassis is
    // composed of:
    //  * a base plate, defined a front and back "foot"
    //  * a hub that supports the spindle
    //  * a guide for the wire being unspooled
    //  * a place for a label.
    // The spindle is a separate piece that's inserted into the spool to be
    // held and then slid into place in the chassis.

    // We define a corner diameter for aesthetics and to avoid some sharp
    // edges.
    corner_d = max(3, wall_th);

    // Our spindle's diameter is slightly smaller than id so that the spool
    // can spin freely.
    spindle_d = id - clearance;
    
    // That means the spool can translate radially as much as:
    play = (id - spindle_d)/2;
    
    // The spindle must be high enough that the spool clears the base plate.
    // Note that most of the assembly process has the spindle centered on the
    // origin, and we translate by spindle_zoffset at the end.
    spindle_zoffset = wall_th + clearance + od/2 + play;

    // We flatten the bottom of the spindle so it can be printed without
    // supports.
    spindle_crop = 0.66*spindle_d/2;
    
    // The spindle has keys on the ends that mate with slots in the chassis.
    key_h = max(0.9*wall_th, 1.75);
    key_w = max(key_h, min(spindle_d, 2*wall_th));

    // The hub supports the spindle.
    hub_d = spindle_d;

    // The overall width of the chassis.
    width = wall_th + clearance + w + clearance + wall_th;
    right = width/2;
    left = -right;

    // The back of the bracket extends just past the back of the spool.
    back = od/2 + play + clearance;
    
    guide_h = max(wire_d + corner_d, 5);
    guide_th = max(wall_th, 3);
    
    // The guide must be far enough forward that the spool can clear it when
    // lifted straight up.
    guide_y = -(od/2 + clearance + guide_th);
    // Ideally, the guide height is even with the top of the spool.
    guide_z = od/2 - play;

    label_h = 13;  // about 1/2" for p-touch labels

    // The front of the bracket must be far enough forward that drag on
    // the guide is unlikely to tip the bracket.
    front = min(-back, guide_y);
    depth = back - front;

    bottom = -(od/2 + play + clearance + wall_th);
    top = guide_z + guide_h/2;
    height = top - bottom;

    module corner(d=corner_d) {
        rotate(90*yhat) cylinder(d=d, h=width, center=true);
    }
    
    module hub() {
        rotate(90*yhat) cylinder(d=hub_d, h=width, center=true);
    }
    
    module base() {
        translate((bottom + corner_d/2)*zhat) union() {
            translate((back - corner_d/2)*yhat) corner();
            translate((front + corner_d/2)*yhat) corner();
        }
    }
    
    module guide() {
        module funnel() {
            rotate(90*yhat) hull() {
                translate(-guide_th/2*yhat) rotate(-90*xhat) cylinder(d=wire_d, h=0.02, center=true);
                translate(guide_th/2*yhat) capsule(d=max(wire_d, guide_h-2), length=w);
            }
        }

        translate([0, guide_y, guide_z])
        translate(guide_th/2*yhat) difference() {
            hull() {
                translate((guide_h - guide_th)/2*zhat) corner(d=guide_th);
                translate((-guide_h + guide_th)/2*zhat) corner(d=guide_th);
            }
            funnel();
        }
    }
    
    module label() {
        translate([0, front + corner_d/2, bottom + corner_d/2]) hull() {
            corner();
            translate(label_h*zhat) corner();
        }
    }

    module chassis() {
        // The envelope defines the outer shape of the bracket.
        module envelope() {
            union() {
                hull() {
                    hub();
                    base();
                    label();
                    guide();
                }
            }
        }
        
        // This defines the y-axis channel that, when cut out of the
        // envelope, gives us the essential shape of the chassis.
        module channel() {
            l = left + wall_th + corner_d/2;
            r = -l;
            b = bottom + wall_th + corner_d/2;
            t = bottom + height;
            corners = [
                [r, b],
                [r, t],
                [l, t],
                [l, b]            
            ];
            
            translate((back + 1)*yhat)
            rotate(90*xhat)
            hull() {
                for (corner = corners) {
                    translate(corner) cylinder(d=corner_d, h=depth+2);
                }
            }
        }

        module spindle_slot() {
            rotate(90*zhat) linear_extrude(height=od)
            key_profile(height=key_h, width=key_w, clearance=0.3);
        }
        
        union() {
            difference() {
                envelope();
                channel();
                
                // Slots to support the spindle
                translate((-spindle_d/2 + spindle_crop)*zhat) union() {
                    translate((left + wall_th)*xhat) spindle_slot();
                    translate((right - wall_th)*xhat) mirror(xhat) spindle_slot();
                }
            }
            guide();
            label();
        }
    }

    module spindle() {
        module key() {
            linear_extrude(height=spindle_d)
                key_profile(height=key_h, width=key_w, extend=clearance/2);
        }
        
        intersection() {
            union() {
                rotate(90*yhat)
                cylinder(d=spindle_d, h=w+clearance, center=true);
                translate(-spindle_d/2 * zhat) union() {
                    translate((left + wall_th)*xhat) rotate(90*zhat) key();
                    translate((right - wall_th)*xhat) rotate(-90*zhat) key();
                }
            }
            
            // Intersecting with the hub rounds off the tops of the keys.
            hub();
            
            // Crop the bottom of the spindle for easy printing.
            translate(spindle_crop*zhat) cube([width, spindle_d, spindle_d], center=true);
        }
    }

    echo("Spool Holder Dimensions", width, depth, height);

    if ($preview) {
        // In preview mode (F5 in OpenSCAD), we show the parts assembled.
        translate([0, -front, spindle_zoffset]) union() {
            chassis();
            spindle();
            // The spool is just for visualization.
            %translate(-play*zhat) rotate(90*yhat) spool(w, od, id);
            // As is this mock label.
            color("#FFFFFF") translate([left, front - 0.01, bottom + corner_d/2]) cube([width, 0.01, 25.4/2]);
        }
    } else {
        // In a full rendering (F6), we turn the chassis face down so that
        // it can be printed without supports.
        rotate(90*xhat) translate(-front*yhat) chassis();
        // And we move the spindle next to the chassis.
        translate([0, -(spindle_zoffset + spindle_d/2 + 1), spindle_d/2 - spindle_crop]) spindle();
    }
}

// A typical small spool of hook-up wire:
//spool_holder(wire_d=2, w=22, $fs=0.1, $fa=6);

// A larger spool:
//translate(38*xhat)
spool_holder(wire_d=3, w=36, od=72, $fs=0.1, $fa=6);

// A spool of specialty wire:
//translate(74*xhat)
//spool_holder(wire_d=0.4, w=16, od=70, id=10, $fs=0.1, $fa=6);
