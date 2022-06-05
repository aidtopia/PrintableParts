// Wire Spool Holder
// Adrian McCarthy 2022-05-01

// Diameter of the wire on the spool, including the insulation. Overestimates are safer than underestimates. (mm)
Wire_Diameter = 2; // [1:0.1:5]

// Width of the spool. (mm)
Spool_Width = 22; // [12:2:70]

// Outer diameter of the spool itself. (mm)
Spool_Outer_Diameter = 55; // [25:5:100]

// Inner diameter of the spool. (mm)
Spool_Inner_Diameter = 25.5; // [7.5:0.5:50]

// Make the spool holder mountable to 35mm DIN rail.
DIN_Mount = true;

// Some dimensions will be optimized according to the diameter of the nozzle on your 3D printer. If unknown, the default (0.4) should be adequate. (mm)
Nozzle_Diameter = 0.4; // [0.1:0.1:1.0]

module __Customizer_Limit__ () {}

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

use <aidutil.scad>
use <aidbolt.scad>

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

// w, od, and id describe the size of the spool to be held
module spool_holder(wire_d=3, w=22, od=55, id=25.5, wall_th=3, din_mount=false, nozzle_d=0.4) {
    clearance = min(1, 2*nozzle_d);
    corner_r = wall_th/2;
    
    base_th = wall_th;
    
    // Our spindle's diameter is slightly smaller than id so that the spool
    // can spin freely.
    spindle_d = id - clearance;
    
    // That means the spool can translate radially as much as:
    play = (id - spindle_d)/2;
    
    // The spindle must be high enough that the spool clears the base plate.
    spindle_zoffset = base_th + clearance + od/2 + play;

    // We'll flatten the bottom of the spindle so it can be printed without
    // supports, require less material, and not roll off the desk.  (Note
    // that the play in upward directions will be even more than our
    // current `play` variable.  Fortunately, that doesn't matter for the
    // dimensions we must compute.)
    spindle_crop = spindle_d/3;
    
    spindle_w = clearance + w + clearance;
    
    // The hub supports the spindle.
    hub_d = id + clearance;

    // The overall width of the chassis.
    width = wall_th + spindle_w + wall_th;
    right = width/2;
    left = -right;

    label_h = 15;  // about 1/2" for p-touch labels
    wire_h = max(wall_th, 3*wire_d/2);
    guide_h = base_th + label_h + wire_h;
    guide_angle = din_mount ? 35 : 15;
    guide_y = guide_h * cos(guide_angle);

    // The back of the bracket extends just past the back of the spool.
    back = od/2 + play + clearance;
    // The front of the bracket extends a bit farther to ensure the spool
    // doesn't hit the guide.
    front = -(back + sin(guide_angle)*guide_h);
    depth = back - front + wall_th;

    top = hub_d/2;
    bottom = 0 - od/2 - play - clearance - base_th;
    height = top - bottom;

    hub         = [0, 0, hub_d/2];
    back_foot   = [back, bottom + corner_r, corner_r];
    front_foot  = [front, bottom + corner_r, corner_r];
    guide_top   = [-back, bottom + corner_r + guide_y, corner_r];

    // 35mm DIN rail dimensions
    din_notch_size = 5 + nozzle_d;
    din_notch_depth = 4;
    din_rail_th = 1 + nozzle_d;
    din_hook_depth = din_notch_depth - din_rail_th;

    echo(str("Spool Holder Dimensions: ", width, " mm wide; ", depth, " mm deep; ", height, " mm high"));
    
    module profile() {
        points = [ front_foot, guide_top, hub, back_foot ];
        hull()
            for (p=points)
                translate([p.x, p.y]) circle(r=p.z, $fs=nozzle_d/2);
    }
    
    module profile_envelope() {
        rotate([90, 0, 0]) rotate([0, 90, 0])
            linear_extrude(width, center=true)
                profile();
    }
    
    module channel() {
        translate([-spindle_w/2, front-wall_th/2, bottom+base_th])
        cube([spindle_w, depth, height]);
    }
    
    module guide() {
        points = [ [0, 0, corner_r], [0, guide_h, corner_r] ];
        translate([0, front, bottom + points[0].z])
        rotate([90-guide_angle, 0, 0])
        difference() {
            rotate([0, 90, 0]) {
                linear_extrude(width, center=true) hull() {
                    for (p=points)
                        translate([p.x, p.y])
                            circle(r=p.z, $fs=nozzle_d/2);
                }
            }
            
            // opening for the wire
            translate([0, base_th + label_h + wire_h/2, 0])
                cylinder(h=wall_th+0.1, d1=2*wire_d+nozzle_d, d2=wire_d+nozzle_d, center=true, $fs=nozzle_d/2);
            
            // recess for the label
            translate([0, base_th + label_h/2, wall_th-nozzle_d])
                cube([width, label_h, wall_th], center=true);
        }
    }
    
    module key(w=1, h=1, clearance=0) {
        points = [
            [0.50, -0.01],
            [0.50, 0.00],
            [0.25, 1.00],
            [-0.25, 1.00],
            [-0.50, 0.00],
            [-0.50, -0.01]
        ];
        offset(delta=clearance, chamfer=true) scale([w, h]) polygon(points);
    }
    
    module spindle(clearance=0) {
        intersection() {
            union() {
                rotate([0, 90, 0])
                    cylinder(h=spindle_w, d=spindle_d, center=true, $fs=nozzle_d/2, $fa=4);
                
                key_w = wall_th;
                key_h = 2*wall_th/3;
                translate([spindle_w/2, 0, 0]) rotate([0, -30, -90])
                    linear_extrude(2*spindle_d, center=true)
                        key(key_w, key_h, clearance);
                translate([-spindle_w/2, 0, 0]) rotate([0, 30, 90])
                    linear_extrude(2*spindle_d, center=true)
                        key(key_w, key_h, clearance);
            }
            
            // intersect with offset box to flatten the bottom
            translate([0, 0, spindle_crop])
                cube([width, spindle_d, spindle_d], center=true);
            
            // intersect with envelope so keys match chassis profile
            profile_envelope();
        }
    }
    
    module din_cutout(tab_w=7) {
        lower = 0;
        upper = lower + 35 + nozzle_d;
        
        points = [
            [lower, -1],
            [lower, din_notch_depth],
            [lower + din_notch_size, din_notch_depth],
            [lower + din_notch_size, 0, clearance],
            [upper - din_notch_size - din_notch_depth, 0, clearance],
            [upper - din_notch_size, din_notch_depth],
            [upper, din_notch_depth],
            [upper, din_hook_depth],
            [upper - din_hook_depth, din_rail_th, clearance],
            [upper - din_hook_depth, 0, clearance],
            [upper - din_hook_depth, -1]
        ];
        
        // For the DIN rails themselves:
        rotate([0, 0, 90]) rotate([90, 0, 0]) {
            linear_extrude(width+clearance, convexity=10, center=true)
                polygon(rounded_polygon(points, $fs=nozzle_d/2));
        }
        
        // For the snap tabs that grab the "lower" rail.
        offset = tab_w;
        translate([-offset, 0, 0])
        translate([-(tab_w + clearance)/2, -4, -clearance/2])
            cube([tab_w+clearance, 4+clearance, base_th+clearance]);
        translate([ offset, 0, 0])
        translate([-(tab_w + clearance)/2, -4, -clearance/2])
            cube([tab_w+clearance, 4+clearance, base_th+clearance]);
    }
    
    module din_snap_tabs(w=7) {
        thick = 5*nozzle_d;
        thin = 2*nozzle_d;
        points = rounded_polygon([
            [-2.5, 0],
            [0, 0],
            [2, din_hook_depth, nozzle_d],
            [0, din_hook_depth],
            [0, din_notch_depth],
            [0, guide_y],
            [-thick, guide_y - thick*cos(guide_angle)],
            [-thin, din_notch_depth, 10]
        ], $fs=nozzle_d/2);
        offset = w;
        translate([-offset, 0, 0])
        rotate([0, 0, 90]) rotate([90, 0, 0])
            linear_extrude(w, center=true, convexity=10)
                polygon(points);
        translate([ offset, 0, 0])
        rotate([0, 0, 90]) rotate([90, 0, 0])
            linear_extrude(w, center=true, convexity=10)
                polygon(points);
    }
    
    module chassis() {
        anchor_h = max(base_th, bolt_head_height("#6-32", "flat"));
        tab_w = min(7, width/5);
        
        difference() {
            union() {
                difference() {
                    profile_envelope();
                    channel();
                }
                guide();
                translate([0, back-1.5*wall_th, bottom+clearance])
                    boss("#6-32", anchor_h);
            }
            
            // subtracting out the spindle with clearance gives us the
            // slots for the spindle keys
            spindle(clearance=nozzle_d/2);
            
            // a screw hole near the back
            translate([0, back-1.5*wall_th, bottom+clearance+anchor_h])
                bolt_hole("#6-32", 5, head="flat");
            
            // notches for mounting on DIN rail
            if (din_mount) {
                translate([0, -back, bottom]) din_cutout(tab_w);
            }
        }
        
        if (din_mount) translate([0, -back, bottom]) din_snap_tabs(tab_w);
    }
    
    translate([0, 0, -bottom]) {
        chassis();
        if ($preview) {
            // In preview mode (F5 in OpenSCAD), show the parts assembled.
            spindle();
            #translate([0, 0, -play]) rotate([0, 90, 0]) spool(w, od, id);
        } else {
            // arrange parts for printing
            translate([0, back + wall_th + spindle_d/2, bottom + spindle_crop/2]) spindle();
        }
    }
}

spool_holder(wire_d=Wire_Diameter,
             w=Spool_Width,
             od=Spool_Outer_Diameter,
             id=Spool_Inner_Diameter,
             wall_th=3,
             din_mount=DIN_Mount,
             nozzle_d=Nozzle_Diameter);
