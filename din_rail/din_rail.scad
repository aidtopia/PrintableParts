// Experimenting with DIN rails, specifically, top-hat 35mm high by 7.5mm deep ones.

module tophat_35_75_profile() {
    polygon(points=[
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
    ]);
}

module clip_profile(clearance=0.4) {
    polygon(points=[
        // inner vertical
        [0-clearance, 1],
        [0-clearance, 35+clearance],
        // top hook
        [1, 35+clearance],
        [3+clearance, 32],
        [4, 32],
        [4, 40],
        // outer vertical
        [-10, 40],
        [-10, -1],
        // cantilever snap
        [5, -1],
        [5, 0-clearance],
        [1+clearance, 1],
        [1+clearance, 0-clearance],
        [-7.75, 0],
        [-8, 0.25],
        [-8, 0.75],
        [-7.75, 1]
    ]);
}

function sum_of_squares(v) = v*v;

function magnitude(v) = sqrt(sum_of_squares(v));

function normalized(v) = 1/magnitude(v) * v;

function set_radii(points, r) = [ for (i=points) [i.x, i.y, r] ];

function wrap_path(points) =
  [points[len(points) - 1], each points, points[0]];

// Returns coefficients (A, B, C) to represent the line from pt0 to pt1
// in the form Ax + By + C = 0.
function line_coeffs(pt0, pt1) =
    let (rise=pt1.y - pt0.y, run=pt1.x - pt0.x,
         A=rise, B=-run, C=-A*pt0.x - B*pt0.y)
    [A, B, C];

// Returns the distance between the 2D point and a line in its
// (A, B, C) form.
function point_to_line(point, line) =
    abs(line[0]*point.x + line[1]*point.y + line[2]) /
    sqrt(line[0]*line[0] + line[1]*line[1]);

function push_to_circumference(p, focus, radius) =
        focus + normalized(p - focus)*radius;

function mid(a, b) = a + 0.5*(b - a);

function arc(focus, r, p1, p2, depth=0) =
    depth >= 10 ? [] :
    magnitude(p1-p2) <= $fs ? [] :
        let (midpoint = push_to_circumference(mid(p1, p2), focus, r))
            [each arc(focus, r, p1, midpoint, depth=depth+1),
             midpoint,
             each arc(focus, r, midpoint, p2, depth=depth+1)];

function round_the_corners(points) =
    let(path = wrap_path(points)) [
        for (i = [1:len(path)-2])
            let (
                A = [path[i-1].x, path[i-1].y],  // adjacent vertex
                B = [path[i].x, path[i].y],      // current vertex
                C = [path[i+1].x, path[i+1].y],  // adjacent vertex
                r = path[i][2],                  // desired radius of arc
                Ahat = normalized(A - B),        // unit vectors pointing from B...
                Chat = normalized(C - B),        // ...to adjacent vertices
                Fhat = normalized(Ahat + Chat),  // bisects angle between Ahat-Chat
                costheta = Fhat*Ahat,            // dot of unit vectors is cosine
                sintheta = sqrt(1 - costheta*costheta),
                offset = r / sintheta,           // distance along Fhat from B to F
                F = B + offset*Fhat,             // F is the focus of the arc
                Aprime = B + offset*costheta*Ahat, // endpoints of the arc
                Cprime = B + offset*costheta*Chat
            )
            each [ Aprime,
                   each arc(F, r, Aprime, Cprime),
                   Cprime ]
    ];

function test2(points) =
    let(path = wrap_path(points)) [
        for (i = [1:len(path)-2])
            let (
                A = [path[i-1].x, path[i-1].y],  // adjacent vertex
                B = [path[i].x, path[i].y],      // current vertex
                C = [path[i+1].x, path[i+1].y],  // adjacent vertex
                r = path[i][2],                  // desired radius of arc
                Ahat = normalized(A - B),        // unit vectors pointing from B...
                Chat = normalized(C - B),        // ...to adjacent vertices
                Fhat = normalized(Ahat + Chat),  // bisects angle between Ahat-Chat
                costheta = Fhat*Ahat,            // dot of unit vectors is cosine
                sintheta = sqrt(1 - costheta*costheta),
                offset = r / sintheta,           // distance along Fhat from B to F
                F = B + offset*Fhat,             // F is the focus of the arc
                Aprime = B + offset*costheta*Ahat, // endpoints of the arc
                Cprime = B + offset*costheta*Chat
            )
            [ F, r ]
    ];


module test() {
    echo("$fn = ", $fn, " $fs = ", $fs, " $fa = ", $fa);
    shape = [
        // x       y       r
        [  0,      0,      2],
        [ -5,     20,      2],
        [  7,      7,      2],
        [ 30,      0,      2]
    ];
    rounded = round_the_corners(shape, $fs=0.5);
    //for (p=rounded) translate([p.x, p.y]) cylinder(h=1, r=0.1);
    polygon(rounded);
    #translate([0, 0, -1]) polygon([ for (p=shape) [p.x, p.y] ]);
    //#for (a=test2(shape)) translate([a[0].x, a[0].y, 0]) cylinder(h=2, r=a[1], $fs=0.2);
}

//linear_extrude(height=9) clip_profile(0.2);
//#linear_extrude(height=9) { tophat_35_75_profile(); }
test();
