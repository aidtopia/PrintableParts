// Wire Spool Brackets
// Adrian McCarthy

// Turn a Sterilite 6-quart storage bin into a dispenser for spools of
// hookup wire.  This file creates two brackets that fit into the ends
// of the storage box and holds a pair of 1/2-inch schedule 40 PVC pipe
// to act as the axes for the spools.

// 1.  Print these brackets.
// 2.  Cut 2 lengths of 1/2-inch schedule 40 PVC pipe to approximately
//     11.25 inches.
// 3.  Put your smaller spools on one pipe and your larger ones on the
//     other, then cap the pipes with the spool brackets.  The flat
//     sides of the bracket should face the spools.  The pipe with the
//     smaller spools should be in the lower position.
// 4.  Place the assembly in your Sterilite 6-quart storage bin.
// 5.  Drill (or melt) holes in the storage container to feed the wires
//     out.  Label the holes with the wire type and gauge.

id=22;  // a 22 mm diameter hole fits around 1/2" schedule 40 PVC pipe
od=25;

// Hookup wire spools seem to come in two sizes.  Both have holes of 1",
// which easily fits over the 1/2-inch pipe.  Larger spools have a
// diameter of 2 7/8" and the smaller ones, 2 3/16".

large_d = 73;
small_d = 56;

// The spool diameters and the inner dimensions of the storage bin
// dictate these positions:
back = [0, 0, 0];
front = [125, 0, 0];
lower = [110, 30, 0];
upper = [30, 60, 0];

// The brackets are made from craft-stick shapes we'll call struts.
module strut(p0, p1, d, h=3) {
    hull() {
        translate(p0) cylinder(d=d, h=h);
        translate(p1) cylinder(d=d, h=h);
    }
}

module spool_bracket() {
    difference() {
        union() {
            strut(back,  front, od);
            strut(front, lower, od);
            strut(lower, upper, od);
            strut(upper, back,  od);
            translate(lower) cylinder(d=od, h=12);
            translate(upper) cylinder(d=od, h=12);
        }
        translate([upper[0], upper[1], -1]) cylinder(d=id, h=14);
        translate([lower[0], lower[1], -1]) cylinder(d=id, h=14);
    }
}

// It takes two brackets that are mirror images of each other.
spool_bracket();
translate([125, 86, 0]) mirror([1,0,0]) spool_bracket();
