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

Bolt_Size = "M3"; // [M2, M3, M4, #2-56, #4-40, #6-32, 1/4-20]

// (mm, 7 mm ≈ 1/4", 13 mm ≈ 1/2")
Bolt_Length = 10; // [4:1:15]

Mating_Thread = "recessed hex nut"; // [none, tapped, recessed hex nut, heat-set insert]

module __Customizer_Limit__ () {}  // End of Customizable Parameters

use <../aidutil.scad>;
use <../aidbolt.scad>;

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
        thClip = round_up(2, n),

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
        xBeamBase = xCatch - lBeam,
        xBack  = xRail - thClip,
        xKickBack = xBeamBase - thClip,

        yRail = 35 + c,
        yOHang = yRail - 3,
        yTop = yRail + thClip,
        yBeamCatch = 0 - c,
        yBeamBase = yBeamCatch + thBeamBase - thBeamCatch,
        yKickBack = yBeamBase + 1 + thClip,
        yBottom = yBeamBase - thBeamBase,
        yPlateau = deflBeam
    ) [
        //  x               y               r
        // the edge that rests against the DIN rail
        [   xRail,          yBeamBase,      2*n     ],
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
        [  xBack,           yTop,           2*n     ],
        [  xBack,           yKickBack,      2*n     ],
        [  xKickBack,       yKickBack,      2*n     ],
        [  xKickBack,       yBottom,        2*n     ],
        // cantilever snap
        [  xTips,           yBottom,        rTips   ],
        [  xTips,           yBeamCatch,     rTips   ],
        [  xPlateau,        yPlateau,       1.0     ],
        [  xCatch,          yPlateau,       0.0     ],
        [  xCatch,          yBeamCatch,     0.2     ],
        [  xBeamBase,       yBeamBase,      rFillet ],
        [  xBeamBase,       yBeamBase+1,    rFillet ]
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
    lScrews = max(10, Bolt_Length);
    zScrews = width / 2;
    yCenter = 35 / 2;
    xMount = 0 - lScrews - Nozzle_Size/2;
    difference() {
        DIN_clip(width);
        translate([xMount, yCenter, zScrews]) {
                                     rotate([0, -90, 0]) bolt_hole(Bolt_Size, lScrews, Mating_Thread);
            translate([0,  12.5, 0]) rotate([0, -90, 0]) bolt_hole(Bolt_Size, lScrews, Mating_Thread);
            translate([0, -12.5, 0]) rotate([0, -90, 0]) bolt_hole(Bolt_Size, lScrews, Mating_Thread);
        }
    }
}

DIN_adapter(Clip_Width);
