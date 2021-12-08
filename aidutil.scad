// Utility functions for OpenSCAD
// Adrian McCarthy 2021

// These interfaces may change.  No promises.

// GENERAL PURPOSE FUNCTIONS

function front(v) = v[0];
function drop_front(v) = len(v) > 1 ? [ for (i=[1:len(v)-1]) v[i] ] : [];
function back(v)  = v[len(v) - 1];
function drop_back(v)  = len(v) > 1 ? [ for (i=[0:len(v)-2]) v[i] ] : [];

// Just an alias for OpenSCAD's norm.
function magnitude(v) = norm(v);

function mid(a, b) = a + 0.5*(b - a);

// Returns a unit length vector in the same direction.
function normalized(v) =
    let(length = magnitude(v))
        (length != 0) ? 1/length * v : 0 * v;

// Rounds n to a multiple of base.
function round_up(n, base=1) =
    n % base == 0 ? n : floor((n+base)/base)*base;

// TABLE LOOKUP FUNCTIONS
    
function find_row(key, table, low, high) =
  low > high ? undef :
  let(i = round_up(mid(low, high)))
    table[i][0] == key ? table[i] :
    table[i][0] <  key ? find_row(key, table, i+1, high) :
                         find_row(key, table, low, i-1);

function find_params(key, table) =
    find_row(key, table, 0, len(table) - 1);

function remap_key(key, mapping) =
    let(mapped = find_params(key, mapping))
        is_undef(mapped) ? key : mapped[1];

// STRING MANIPULATION FUNCTIONS

// Returns a string consisting of `count` characters of `input` starting at
// `offset`.  If count is not specified, returns the rest of the string (up to
// a limit to prevent runaway recursion).
function substr(input, offset, count=99) =
    count <= 0 ? "" :
    offset >= len(input) ? "" :
    str(input[offset], substr(input, offset+1, count-1));

// Returns a vector of the substrings of `input` separated by the specified
// `delimiter`.  The substrings exclude the delimiter itself.
function split(input, delimiter=" ") =
    assert(len(delimiter) == 1)
    let (breaks = [-1, each search(delimiter, input, 0)[0], len(input)])
        [ for (i=[1:len(breaks)-1])
            let (from = breaks[i-1] + 1, to = breaks[i])
                if (to > from) substr(input, from, to-from) ];

// Returns a string by concatenating the string versions of the elements of
// the vector `input`.  You can optionally specify a `joiner` to connect the
// elements.
function join(input, joiner="", offset=0) =
    offset >= len(input) ? "" :
    offset == 0 ? str(input[0], join(input, joiner, 1)) :
    str(joiner, input[offset], join(input, joiner, offset+1));

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

function remove_adjacent_duplicates(points) = [
    points[0],
    each [for (i = [1:len(points)-2]) if (points[i] != points[i-1]) points[i]],
    each [for (i = len(points)-1) if (points[i] != points[0]) points[i]]
];

// Returns a copy of the vector with additional points mirroring the original
// ones reflected in x.
function mirror_path(points) =
    remove_adjacent_duplicates([
        each points,
        each [ for (j=[1:len(points)]) let(i=len(points)-j)
                   [-points[i].x, points[i].y, points[i][2]] ]
    ]);

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

// Given a list of (x, y, radius) points, this returns a corresponding list of
// (x, y) points that represent the rounded version of the polygon.  The
// result can be passed directly to OpenSCAD's polygon.
function rounded_polygon(points) = [
    for (a = compute_arcs(points))
        let (F = a[0], r = a[1], Aprime = a[2], Cprime = a[3])
            each [ Aprime, each arc(F, r, Aprime, Cprime), Cprime]
];
