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

make_coins();
