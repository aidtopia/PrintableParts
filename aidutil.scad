// Utility functions for OpenSCAD
// Adrian McCarthy 2021

// These interfaces may change.  No promises.

// GENERAL PURPOSE FUNCTIONS

// Just an alias for OpenSCAD's norm.
function magnitude(v) = norm(v);

function mid(a, b) = a + 0.5*(b - a);

// Returns a unit length vector in the same direction.
function normalized(v) = 1/magnitude(v) * v;

// Rounds n to a multiple of base.
function round_up(n, base=1) = n % base == 0 ? n : floor(n+base/base)*base;

// 2D FUNCTIONS

// Returns coefficients (A, B, C) to represent the line from pt0 to pt1
// in the form Ax + By + C = 0.  (XY plane only!)
function line_coeffs(pt0, pt1) =
    let (rise=pt1.y - pt0.y, run=pt1.x - pt0.x,
         A=rise, B=-run, C=-A*pt0.x - B*pt0.y)
    [A, B, C];

// Returns the distance between a 2D point and a line in (A, B, C) form.
function point_to_line(point, line) =
    abs(line[0]*point.x + line[1]*point.y + line[2]) /
    sqrt(line[0]*line[0] + line[1]*line[1]);

// ROUNDED POLYGONS
// Define a 2D polygon with (x, y, radius) vertices and get a rounded version.

// Add a default radius to all points.
function set_radii(points, r) = [ for (i=points) [i.x, i.y, r] ];

// Returns a copy of just the (x, y) components of an (x, y, radius) list.
// This is useful for rendering the original polygon without rounding, since
// OpenSCAD's polygon won't ignore the third component.
function clear_radii(points)  = [ for (i=points) [i.x, i.y] ];

// Returns a copy of the vector with a duplicate of the last point at the
// beginning and the first point at the end.  This simplifies indexing the
// previous and next point.
function wrap_path(points) =
    [points[len(points) - 1], each points, points[0]];

// Projects point p to the surface of a circle (or sphere).
function push_to_circumference(p, focus, radius) =
    focus + normalized(p - focus)*radius;

// Recursively generates points on an arc from p1 to p2.  A depth limit avoids
// runaway recursion.  It also stops subdividing once the $fs facet size is
// reached.  Currently, it does not check $fa or $fn.
function arc(focus, r, p1, p2, depth=0) =
    depth >= 8 ? [] :  // prevent runaway recursion
    magnitude(p1-p2) <= $fs ? [] :
        let (midpoint = push_to_circumference(mid(p1, p2), focus, r)) [
            each arc(focus, r, p1, midpoint, depth=depth+1),
            midpoint,
            each arc(focus, r, midpoint, p2, depth=depth+1)
        ];

// Given a polygon in (x, y, radius) form, it computes the parameters necessary
// to generate the arcs to round off the corners.
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

// Given a list of (x, y, radius) points, this returns a corrsponding list of
// (x, y) points that represent the rounded version of the polygon.  The
// result can be passed directly to OpenSCAD's polygon.
function rounded_polygon(points) = [
    for (a = compute_arcs(points))
        let (F = a[0], r = a[1], Aprime = a[2], Cprime = a[3])
            each [ Aprime, each arc(F, r, Aprime, Cprime), Cprime]
];
