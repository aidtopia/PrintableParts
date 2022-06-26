// Coin handling parts
// Adrian McCarthy 2022-06-09

module coin(od, th, head="", clr="DarkGray", reeds=0, internal_sides=1, nozzle_d=0.4) {
    id = od - 4*nozzle_d;
    color(clr)
        translate([0, 0, th/2]) {
            linear_extrude(th, convexity=10, center=true)
                difference() {
                    circle(d=od, $fs=nozzle_d/2);
                    if (internal_sides != 1) {
                        rotate([0, 0, -90]) circle(d=id, $fn=internal_sides);
                    } else {
                        circle(d=id, $fs=nozzle_d/2);
                    }
                    if (reeds > 0) {
                        for (i = [1:reeds]) {
                            rotate([0, 0, i*360/reeds])
                                translate([(od + nozzle_d)/2, 0, 0])
                                    rotate([0, 0, 45])
                                        square(nozzle_d, center=true);
                        }
                    }
                }
                linear_extrude(th-nozzle_d, convexity=10, center=true)
                    circle(d=id, $fs=0.2);

            // Heads
            translate([0, 0, nozzle_d/2])
                linear_extrude(th/2, convexity=10)
                    text(head, size=id/len(head), halign="center", valign="center");
                
            // Tails
            iid = id-2*nozzle_d;
            translate([0, 0, -th/4])
                linear_extrude(th/2, convexity=10, center=true)
                    if (internal_sides != 1) {
                        rotate([0, 0, -90])
                            circle(d=iid, $fn=internal_sides);
                    } else {
                        circle(d=iid, $fs=nozzle_d/2);
                    }
        }
}

USD_coins = [
//   name           od      id      mark    color       reeds   sides
    ["penny",       19.05,  1.52,   "1¢",   "Peru",       0,      1     ],
    ["nickel",      21.21,  1.95,   "5¢",   "DarkGray",   0,      1     ],
    ["dime",        17.91,  1.35,  "10¢",   "DarkGray", 118,      1     ],
    ["quarter",     24.26,  1.75,  "25¢",   "DarkGray", 119,      1     ],
    ["halfdollar",  30.61,  2.15,  "50¢",   "DarkGray", 150,      1     ],
    ["Ikedollar",   38.10,  2.58,   "$1",   "Silver",     0,      1     ],
    ["SBAdollar",   26.50,  2.00,   "$1",   "DarkGray",   0,     11     ],
    ["Sacdollar",   26.49,  2.00,   "$1",   "GoldenRod",  0,      1     ]
];

function cumulative(index, table, column) =
    index < 0 ? 0 :
        table[index][column] +
            (index == 0 ? 0 : cumulative(index-1, table, column));

module make_coins(coins=USD_coins) {
    for (i=[0:len(coins)-1]) {
        c = coins[i];
        translate([cumulative(i, coins, 1) - c[1]/2 + i, 0, 0])
            coin(c[1], c[2], c[3], c[4], c[5], c[6]);
    }
}

module easel(panel_h=100, panel_th=5, peg_th=4, th=6, angle=60, nozzle_d=0.4) {
    peg_l = panel_th+2;
    outer_r = panel_h/20;
    inner_r = 2/3*outer_r;

    module triangle(hypot=panel_h) {
        // A right triangle whose hypotenuse has unit length.
        tri = [
            [0, 0],
            [cos(angle), 0],
            [0, sin(angle)]
        ];
        scale([hypot, hypot]) polygon(tri);
    }
    
    module peg(l, th) {
        translate([0, 0, th/2 - nozzle_d])
            rotate([0, 90, 0])
                linear_extrude(l)
                    translate([0, -th/2])
                        square(th-nozzle_d);
    }
    
    module pegs(l, th, panel_h, margin, delta) {
        translate([0, panel_h*sin(angle), 0])
        rotate([0, 0, 90-angle]) translate([delta, 0, 0]) {
            translate([0, 0        - margin, 0]) peg(l, th);
            translate([0, -panel_h + margin, 0]) peg(l, th);
        }
    }

    module right_bracket() {
        linear_extrude(th, center=true) difference() {
            offset(r=outer_r, $fs=nozzle_d/2) triangle();
            offset(r=inner_r, $fs=nozzle_d/2)
                offset(delta=-(inner_r+outer_r)) triangle();
        }
        
        // Translation pushes the pegs to the edge of the bracket
        // so that it can print without supports.
        translate([0, 0, (peg_th - th)/2])
        pegs(peg_l, peg_th, panel_h, margin=peg_th, delta=outer_r);
    }
    
    module left_bracket() {
        mirror([-1, 0, 0]) right_bracket();
    }
    
    base_x = 2*outer_r + 1;
    translate([-base_x/2, 0, th/2]) left_bracket();
    translate([ base_x/2, 0, th/2]) right_bracket();
}

easel(angle=60);
