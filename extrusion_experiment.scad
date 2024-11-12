module show_points(points) {
    for (i = [0:len(points)-1]) {
        translate(points[i]) {
            sphere(d=1);
            text(str(i), size=3, valign="bottom");
        }
    }
}

function f(r, t, T, peak_width, a) =
    (t % T > peak_width) ?
        r : r + a * sin(180 * (t % T) / peak_width);

function periodic_envelope(da, r, num_bumps, peak_width, amplitude) =
    let (T = 360/num_bumps)
    [ for (t = [0:da:360]) 
        [f(r, t, T, peak_width, amplitude) * cos(t),
         f(r, t, T, peak_width, amplitude) * sin(t)]];

peak_width = 18.0; //degrees
amplitude = 10;
r = 30;
thickness = 2;
da = 1;
num_bumps = 4;

// HACK:  The points must be specified counterclockwise in order for the
// polyhedron faces to be clockwise.
module extrude_between(points0, points1, height, convexity=2) {
    N = len(points0);
    assert(len(points1) == N);
    bottom_pts = [for (i=[0:N-1]) [points0[i].x, points0[i].y, 0]];
    top_pts    = [for (i=[0:N-1]) [points1[i].x, points1[i].y, height]];
    bottom_face = [for (i=[0:N-1]) i];
    top_face    = [for (i=[0:N-1]) 2*N - i - 1];
    side_faces  = [for (i=[0:N-1]) let (j=(i+1)%N) [i+N, j+N, j, i]];
    polyhedron(
        [each bottom_pts, each top_pts],
        [bottom_face, each side_faces, top_face],
        convexity=convexity
    );
}

if (false) {
points0 = periodic_envelope(da, r, num_bumps, peak_width, 3*amplitude);
points1 = periodic_envelope(da, r, num_bumps, peak_width, amplitude);
extrude_between(points0, points1, 120, convexity=4);
} else {
for (slice = [1:120]) {
    amplitude0 = amplitude*sin(slice*5);
    amplitude1 = amplitude*sin((slice+1)*5);
    points0 = periodic_envelope(da, r, num_bumps, peak_width, amplitude0);
    points1 = periodic_envelope(da, r, num_bumps, peak_width, amplitude1);
    translate([0, 0, slice]) {
        extrude_between(points0, points1, 1);
    }
}
}

