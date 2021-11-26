// Jumper Wire Organizer
// Adrian McCarthy 2021
// Inspired by Rex McCarthy's version.

// BEGIN CUSTOMIZER PARAMETERS

// length of the jumper wires between the pin housings (mm)
// (err to a smaller value)
Wire_Length = 145; // [75:5:180]

// typical usage is one slot for each color of wire
Slots = 10; // [1:20]

// maximum number of wires to store in a single slot
Wires_per_Slot = 15; // [5:30]

// distance between the slots (mm)
Spacing = 10;  // [5:1:26]

// some dimensions are optimized to the 3D printer's nozzle diameter (mm)
Nozzle_Size = 0.4; // [0.1:0.05:0.8]

module __END_CUSTOMIZER_PARAMETERS__ () {}


use <aidutil.scad>

module jumper_wire_organizer(
    length=145,     // length of wires (between pin housings)
    slots=10,       // number of colors you want to hold
    depth=15,       // number of wires to fit in each slot
    spacing=10,     // spacing from slot to slot
    thickness=3,    // wall thickness (may be rounded up slightly)
    nozzle_d=0.4
) {
    wire_th = round_up(1.6, nozzle_d);
    wall_th = round_up(thickness, nozzle_d);
    brace_th = round_up(wall_th/2, nozzle_d);
    width  = max(10, slots*spacing + brace_th);
    // Because of the max, we'll compute the effective spacing as step.
    step = (width - brace_th)/slots;
    hollow = step - brace_th;
    offset = brace_th + hollow/2;
    height = depth * 2.54 + wall_th;
    
    big_r = min(depth/2, length/15);
    little_r = wall_th;

    module body() {
        profile = rounded_polygon(mirror_path([
    //        x             y               r
            [ length/2,     0,              0       ],
            [ length/2,     height,         0       ],
            [ length/2-little_r,
                            height,         little_r],
            [ 0,            wall_th+little_r,
                                            big_r   ]
        ]), $fs=nozzle_d/2);
        cutout = rounded_polygon([
    //        x             y               r
            [ wall_th,      wall_th,        big_r   ],
            [ length/2-wall_th,
                            wall_th,        big_r   ],
            [ length/2-wall_th,
                            height-wall_th, big_r   ]            
        ], $fs=nozzle_d/2);
        
        rotate([90, 0, 0]) linear_extrude(width, convexity=10) difference() {
            polygon(profile);
            polygon(cutout);
            mirror([1, 0, 0]) polygon(cutout);
        }
    }
    
    module slot() {
        union() {
            translate([-1, -wire_th/2, 0])
                cube([length+2, wire_th, height]);
            translate([wall_th, -hollow/2, 0])
                cube([length-2*wall_th, hollow, height]);
        }
    }
    
    difference() {
        translate([0, width, 0]) body();
        translate([0, 0, wall_th])
            for (i = [0:slots-1])
                    translate([-length/2, i*step + offset, 0]) slot();
    }
}

jumper_wire_organizer(
    length=Wire_Length,
    slots=Slots,
    depth=Wires_per_Slot,
    spacing=Spacing,
    thickness=3,
    nozzle_d=Nozzle_Size
);
