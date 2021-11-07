// Experimenting with DIN rails (top-hat 35mm high by 7.5mm deep).
// Adrian McCarthy 2021

// Customizable Parameters

// nozzle size determines the clearance between mating parts
nozzle_size = 0.4; // [0:0.1:1]

module __Customizer_Limit__ () {}

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

clip_profile = let (c=nozzle_size/2) [
    // x        y       r
    // inner vertical
    [  0-c,     1,    0.0],
    [  0-c,  35+c,      c],
    // top hook
    [    1,  35+c,      c],
    [   2.5,    32,    0.5],
    [    4,    32,    0.5],
    [    4,    40,    1.0],
    // outer vertical
    [  -10,    40,    1.0],
    [  -10,    -2,    1.0],
    // cantilever snap
    [    6,    -2,    0.5],
    [  1+c,   1+c,    0.0],
    [  1+c,   0-c,    0.2],
    [   -8,     c,    0.3],
    [   -8,     1,    0.3]
];

test_shape = [
    // x       y       r
    [  0,      0,      2],
    [ -5,     20,      2],
    [  7,      7,      2],
    [ 30,      0,      2]
];


function sum_of_squares(v) = v*v;

function magnitude(v) = sqrt(sum_of_squares(v));

function normalized(v) = 1/magnitude(v) * v;

function set_radii(points, r) = [ for (i=points) [i.x, i.y, r] ];
function clear_radii(points)  = [ for (i=points) [i.x, i.y] ];

function wrap_path(points) =
  [points[len(points) - 1], each points, points[0]];

function push_to_circumference(p, focus, radius) =
        focus + normalized(p - focus)*radius;

function mid(a, b) = a + 0.5*(b - a);

function arc(focus, r, p1, p2, depth=0) =
    depth >= 8 ? [] :  // bound the recursion
    magnitude(p1-p2) <= $fs ? [] :
        let (midpoint = push_to_circumference(mid(p1, p2), focus, r))
            [each arc(focus, r, p1, midpoint, depth=depth+1),
             midpoint,
             each arc(focus, r, midpoint, p2, depth=depth+1)];

function compute_arcs(points) =
    let(path = wrap_path(points)) [
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

function rounded_polygon(points) =
    let(arcs = compute_arcs(points)) [
        for (a = arcs)
            let (F = a[0], r = a[1], Aprime = a[2], Cprime = a[3])
                each [ Aprime, each arc(F, r, Aprime, Cprime), Cprime]
    ];

linear_extrude(height=9) polygon(rounded_polygon(clip_profile, $fs=0.2));
#linear_extrude(height=9) polygon(tophat_35_75_profile);
