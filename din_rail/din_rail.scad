// Experimenting with DIN rails (top-hat 35mm high by 7.5mm deep).
// Adrian McCarthy 2021

// TODO:  Needs pull-tab for releasing from the rail.

// TODO:  Simplify the profile so that it's just a clip, and then provide a
// module that incorporates the clip into an adapter.

// Begin Customizable Parameters

// certain dimensions are optimized to the nozzle size used in 3D printing (mm)
Nozzle_Size = 0.4; // [0.1:0.05:0.8]

// length of the snap-fit cantilever (mm)
Beam_Length = 10; // [8:0.5:15]

// width of the DIN clip (mm)
Clip_Width = 9; // [4.5:4.5:27]

Screw_Size = "M3"; // [M2, M3, M3.5, M4, #4-40]

// (mm, 7≈1/4", 13≈1/2")
Screw_Length = 10; // [4:1:15]

Threading = 2; // [0: none, 1:tapped, 2:captive hex nut, 3:heat-set insert]

module __Customizer_Limit__ () {}  // End of Customizable Parameters

use <../aidutil.scad>;

tophat_35_75_profile = [
    [0, 0],
    [0, 5],
    [6.5, 5],
    [6.5, 30],
    [0, 30],
    [0, 35],
    [1, 35],
    [1, 31],
    [7.5, 31],
    [7.5, 4],
    [1, 4],
    [1, 0],
    [0, 0]
];

clip_profile =
    let (
        n = Nozzle_Size,
        c = n/2,        // c for clearances
        thRail = 1,     // DIN rail is 1mm thick
        rTips = round_up(0.5, n),

        thBeamBase = round_up(2, n), // thickness of the cantilever at the base of the beam
        thBeamCatch = round_up(1, n), // thickness of the cantilever at the catch
        deflBeam = 1.5, // how far the cantilever will have to deflect
        lBeam = Beam_Length,     // cantilever beam length (to xCatch)
        rFillet = n,    // radius of fillet at base of cantilever beam
        
        xRail = 0 - c,
        xCatch = xRail + c + thRail + c,
        xPlateau = xCatch + 0.5,
        xOHang = 2*xCatch,
        xTips = min(5*xCatch, 7.5-c),
        xBase = xCatch - lBeam,
        xMount = xRail - max(10, Screw_Length, xCatch-xBase+0.5),

        yRail = 35 + c,
        yOHang = yRail - 3,
        yTop = yRail + 2,
        yBeamCatch = 0 - c,
        yBeamBase = yBeamCatch + thBeamBase - thBeamCatch,
        yBottom = yBeamBase - thBeamBase,
        yPlateau = deflBeam
    ) [
        //  x               y               r
        // the edge that rests against the DIN rail
        [   xRail,          0.0,            2*n     ],
        [   xRail,          yRail,          c       ],
        // the top hook overhangs the top edge of the rail
        [   xCatch,         yRail,          c       ],
        [   xOHang,         yOHang,         3*n     ],
        [   mid(xOHang, xTips),
                            yOHang,         3*n     ],
        // this tip extends the same amount as the cantilever so the clip
        // stands level when placed on a table
        [  xTips,           yTop-1,         rTips   ],
        [  xTips,           yTop,           rTips   ],
        // the edge that the module mounts to
        [  xMount,          yTop,           0.0     ],
        [  xMount,          yBottom,        3*n     ],
        // cantilever snap
        [  xTips,           yBottom,        rTips   ],
        [  xTips,           yBeamCatch,     rTips   ],
        [  xPlateau,        yPlateau,       1.0     ],
        [  xCatch,          yPlateau,       0.0     ],
        [  xCatch,          yBeamCatch,     0.2     ],
        [  xBase,           yBeamBase,      rFillet ],
        [  xBase,           yBeamBase+1,    rFillet ]
    ];

function magnitude(v) = norm(v);

function normalized(v) = 1/magnitude(v) * v;

function set_radii(points, r) = [ for (i=points) [i.x, i.y, r] ];
function clear_radii(points)  = [ for (i=points) [i.x, i.y] ];

function wrap_path(points) =
    [points[len(points) - 1], each points, points[0]];

function push_to_circumference(p, focus, radius) =
    focus + normalized(p - focus)*radius;

function mid(a, b) = a + 0.5*(b - a);

function arc(focus, r, p1, p2, depth=0) =
    depth >= 8 ? [] :  // prevent runaway recursion
    magnitude(p1-p2) <= $fs ? [] :
        let (midpoint = push_to_circumference(mid(p1, p2), focus, r)) [
            each arc(focus, r, p1, midpoint, depth=depth+1),
            midpoint,
            each arc(focus, r, midpoint, p2, depth=depth+1)
        ];

function compute_arcs(points) =
    let (path = wrap_path(points)) [
        for (i = [1:len(path)-2])
            let (
                A = [path[i-1].x, path[i-1].y],  // adjacent vertex
                B = [path[i].x, path[i].y],      // current vertex
                C = [path[i+1].x, path[i+1].y],  // adjacent vertex
                r = is_undef(path[i][2]) ? 0 : path[i][2], // radius of arc

                // Ahat and Chat are unit vectors pointing from B toward
                // vertices A and C, respectively.
                Ahat = normalized(A - B),
                Chat = normalized(C - B),
        
                // Fhat points from B, bisecting the angle formed by AB and CB.
                Fhat = normalized(Ahat + Chat),

                // Theta is the half-angle between the sides meeting at B.
                // The dot product of unit vectors is equal to the cosine of
                // the angle between them.
                costheta = Fhat*Ahat,
                sintheta = sqrt(1 - costheta*costheta),

                // Compute F, the focus (center) of the circle needed to make
                // the arc.
                offset = r / sintheta,
                F = B + offset*Fhat,
                
                // Aprime and Cprime are the points at which the corresponding
                // sides of the polygon are tangent to a circle of radius r at F.
                Aprime = B + offset*costheta*Ahat, // endpoints of the arc
                Cprime = B + offset*costheta*Chat
            )
            [ F, r, Aprime, Cprime ]
    ];

function rounded_polygon(points) = [
    for (a = compute_arcs(points))
        let (F = a[0], r = a[1], Aprime = a[2], Cprime = a[3])
            each [ Aprime, each arc(F, r, Aprime, Cprime), Cprime]
];

module DIN_clip(width=9) {
    linear_extrude(height=width, convexity=15)
        polygon(rounded_polygon(clip_profile, $fs=Nozzle_Size/2));
    if ($preview) {
        #translate([0, 0, -2]) linear_extrude(height=width+4) 
            polygon(tophat_35_75_profile);
    }
}

module DIN_adapter(width=9) {
    zScrews = width / 2;
    yCenter = 35 / 2;
    difference() {
        DIN_clip(width);
        translate([-15, yCenter, zScrews]) rotate([0, 90, 0]) cylinder(h = 30, d = 3.5, $fs=Nozzle_Size/2);
        translate([-15, yCenter + 12.5, zScrews]) rotate([0, 90, 0]) cylinder(h = 30, d = 3.5, $fs=Nozzle_Size/2);
        translate([-15, yCenter - 12.5, zScrews]) rotate([0, 90, 0]) cylinder(h = 30, d = 3.5, $fs=Nozzle_Size/2);

    }
}

DIN_adapter(Clip_Width);
