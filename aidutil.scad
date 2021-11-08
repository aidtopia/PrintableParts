// Utility functions for OpenSCAD
// Adrian McCarthy 2021

// Just and alias for OpenSCAD's norm.
function magnitude(v) = norm(v);

// Returns a unit length vector in the same direction.
function normalized(v) = 1/magnitude(v) * v;

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

// Rounds n to a multiple of base.
function round_up(n, base=1) = n % base == 0 ? n : floor(n+base/base)*base;

