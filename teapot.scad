// The Martin Newell Utah Teapot model.

// Places the index of each point in points at the space in 3D.
// This can be useful for visualization and debugging.
module point_cloud(points) {
    for (i = [0:len(points)-1]) {
        point = points[i];
        translate(point) {
            rotate($vpr)
                scale(0.002)
                    linear_extrude(1)
                        text(str(i), size=10, halign="center", valign="center");
        }
    }
}

function select(points, indexes) =
    [for (i = [0:len(indexes)-1]) points[indexes[i]]];

// Computes a point along a cubic bezier curve.  `t` is a parameter
// from 0 to 1 and `p` defines the curve as four control points.
function bezier(t, p) =
    let (k = 1 - t)
    p[0]*k*k*k + 3*p[1]*k*k*t + 3*p[2]*k*t*t + p[3]*t*t*t;

// Returns vertices for a mesh that represents a bicubic patch.
function patch_vertices(p, divisions=8) =
    [ for (u = [0:1/divisions:1])
        let(cp = [for (i=[0:3]) bezier(u, [for (j=[0:3]) p[i*4+j]])])
        each [ for (v = [0:1/divisions:1]) bezier(v, cp) ] ];

// Returns indices into the vector returned by patch_vertices,
// ordered appropriately for OpenSCAD's polyhedron.
function patch_faces(divisions=8) = [
    for (i=[1:divisions]) each [
        for (j=[0:divisions-1])
            let (n=(divisions+1)*j+i) [n-1, n, n+(divisions+1), n+divisions]]
];

teapot_points = [
    [ 0.2000,  0.0000, 2.70000], [ 0.2000, -0.1120, 2.70000],
    [ 0.1120, -0.2000, 2.70000], [ 0.0000, -0.2000, 2.70000],
    [ 1.3375,  0.0000, 2.53125], [ 1.3375, -0.7490, 2.53125],
    [ 0.7490, -1.3375, 2.53125], [ 0.0000, -1.3375, 2.53125],
    [ 1.4375,  0.0000, 2.53125], [ 1.4375, -0.8050, 2.53125],
    [ 0.8050, -1.4375, 2.53125], [ 0.0000, -1.4375, 2.53125],
    [ 1.5000,  0.0000, 2.40000], [ 1.5000, -0.8400, 2.40000],
    [ 0.8400, -1.5000, 2.40000], [ 0.0000, -1.5000, 2.40000],
    [ 1.7500,  0.0000, 1.87500], [ 1.7500, -0.9800, 1.87500],
    [ 0.9800, -1.7500, 1.87500], [ 0.0000, -1.7500, 1.87500],
    [ 2.0000,  0.0000, 1.35000], [ 2.0000, -1.1200, 1.35000],
    [ 1.1200, -2.0000, 1.35000], [ 0.0000, -2.0000, 1.35000],
    [ 2.0000,  0.0000, 0.90000], [ 2.0000, -1.1200, 0.90000],
    [ 1.1200, -2.0000, 0.90000], [ 0.0000, -2.0000, 0.90000],
    [-2.0000,  0.0000, 0.90000], [ 2.0000,  0.0000, 0.45000],
    [ 2.0000, -1.1200, 0.45000], [ 1.1200, -2.0000, 0.45000],
    [ 0.0000, -2.0000, 0.45000], [ 1.5000,  0.0000, 0.22500],
    [ 1.5000, -0.8400, 0.22500], [ 0.8400, -1.5000, 0.22500],
    [ 0.0000, -1.5000, 0.22500], [ 1.5000,  0.0000, 0.15000],
    [ 1.5000, -0.8400, 0.15000], [ 0.8400, -1.5000, 0.15000],
    [ 0.0000, -1.5000, 0.15000], [-1.6000,  0.0000, 2.02500],
    [-1.6000, -0.3000, 2.02500], [-1.5000, -0.3000, 2.25000],
    [-1.5000,  0.0000, 2.25000], [-2.3000,  0.0000, 2.02500],
    [-2.3000, -0.3000, 2.02500], [-2.5000, -0.3000, 2.25000],
    [-2.5000,  0.0000, 2.25000], [-2.7000,  0.0000, 2.02500],
    [-2.7000, -0.3000, 2.02500], [-3.0000, -0.3000, 2.25000],
    [-3.0000,  0.0000, 2.25000], [-2.7000,  0.0000, 1.80000],
    [-2.7000, -0.3000, 1.80000], [-3.0000, -0.3000, 1.80000],
    [-3.0000,  0.0000, 1.80000], [-2.7000,  0.0000, 1.57500],
    [-2.7000, -0.3000, 1.57500], [-3.0000, -0.3000, 1.35000],
    [-3.0000,  0.0000, 1.35000], [-2.5000,  0.0000, 1.12500],
    [-2.5000, -0.3000, 1.12500], [-2.6500, -0.3000, 0.93750],
    [-2.6500,  0.0000, 0.93750], [-2.0000, -0.3000, 0.90000],
    [-1.9000, -0.3000, 0.60000], [-1.9000,  0.0000, 0.60000],
    [ 1.7000,  0.0000, 1.42500], [ 1.7000, -0.6600, 1.42500],
    [ 1.7000, -0.6600, 0.60000], [ 1.7000,  0.0000, 0.60000],
    [ 2.6000,  0.0000, 1.42500], [ 2.6000, -0.6600, 1.42500],
    [ 3.1000, -0.6600, 0.82500], [ 3.1000,  0.0000, 0.82500],
    [ 2.3000,  0.0000, 2.10000], [ 2.3000, -0.2500, 2.10000],
    [ 2.4000, -0.2500, 2.02500], [ 2.4000,  0.0000, 2.02500],
    [ 2.7000,  0.0000, 2.40000], [ 2.7000, -0.2500, 2.40000],
    [ 3.3000, -0.2500, 2.40000], [ 3.3000,  0.0000, 2.40000],
    [ 2.8000,  0.0000, 2.47500], [ 2.8000, -0.2500, 2.47500],
    [ 3.5250, -0.2500, 2.49375], [ 3.5250,  0.0000, 2.49375],
    [ 2.9000,  0.0000, 2.47500], [ 2.9000, -0.1500, 2.47500],
    [ 3.4500, -0.1500, 2.51250], [ 3.4500,  0.0000, 2.51250],
    [ 2.8000,  0.0000, 2.40000], [ 2.8000, -0.1500, 2.40000],
    [ 3.2000, -0.1500, 2.40000], [ 3.2000,  0.0000, 2.40000],
    [ 0.0000,  0.0000, 3.15000], [ 0.8000,  0.0000, 3.15000],
    [ 0.8000, -0.4500, 3.15000], [ 0.4500, -0.8000, 3.15000],
    [ 0.0000, -0.8000, 3.15000], [ 0.0000,  0.0000, 2.85000],
    [ 1.4000,  0.0000, 2.40000], [ 1.4000, -0.7840, 2.40000],
    [ 0.7840, -1.4000, 2.40000], [ 0.0000, -1.4000, 2.40000],
    [ 0.4000,  0.0000, 2.55000], [ 0.4000, -0.2240, 2.55000],
    [ 0.2240, -0.4000, 2.55000], [ 0.0000, -0.4000, 2.55000],
    [ 1.3000,  0.0000, 2.55000], [ 1.3000, -0.7280, 2.55000],
    [ 0.7280, -1.3000, 2.55000], [ 0.0000, -1.3000, 2.55000],
    [ 1.3000,  0.0000, 2.40000], [ 1.3000, -0.7280, 2.40000],
    [ 0.7280, -1.3000, 2.40000], [ 0.0000, -1.3000, 2.40000],
    // extra points for the non-standard bottom
    [ 0.0000,  0.0000, 0.00000], [ 1.4250, -0.7980, 0.00000],
    [ 1.5000,  0.0000, 0.07500], [ 1.4250,  0.0000, 0.00000],
    [ 0.7980, -1.4250, 0.00000], [ 0.0000, -1.5000, 0.07500],
    [ 0.0000, -1.4250, 0.00000], [ 1.5000, -0.8400, 0.07500],
    [ 0.8400, -1.5000, 0.07500]
];

module teapot(divisions=4) {
    // Each bicubic patch is defined by 16 control points.  The
    // values here are indices into teapot_points.
    lid_patches = [
        [  96,  96,  96,  96,  97,  98,  99, 100,
          101, 101, 101, 101,   0,   1,   2,   3 ],
        [   0,   1,   2,   3, 106, 107, 108, 109,
          110, 111, 112, 113, 114, 115, 116, 117 ]
    ];
    rim_patches = [
        [ 102, 103, 104, 105,   4,   5,   6,   7,
            8,   9,  10,  11,  12,  13,  14,  15 ]
    ];
    body_patches = [
        [  12,  13,  14,  15,  16,  17,  18,  19,
           20,  21,  22,  23,  24,  25,  26,  27 ],
        [  24,  25,  26,  27,  29,  30,  31,  32,
           33,  34,  35,  36,  37,  38,  39,  40 ]
    ];

    // The bottom was not part of Martin Newell's original model.
    bottom_patches = [
        [ 118, 118, 118, 118, 124, 122, 119, 121,
          123, 126, 125, 120,  40,  39,  38,  37 ]
    ];

    handle_patches = [
        [  41,  42,  43,  44,  45,  46,  47,  48,
           49,  50,  51,  52,  53,  54,  55,  56 ],
        [  53,  54,  55,  56,  57,  58,  59,  60,
           61,  62,  63,  64,  28,  65,  66,  67 ]
    ];
    spout_patches = [
        [  68,  69,  70,  71,  72,  73,  74,  75,
           76,  77,  78,  79,  80,  81,  82,  83 ],
        [  80,  81,  82,  83,  84,  85,  86,  87,
           88,  89,  90,  91,  92,  93,  94,  95 ]
    ];

    module patch_mesh(patch_indices, divisions) {
        control_points = select(teapot_points, patch_indices);
        mesh_vertices = patch_vertices(control_points, divisions);
        faces = patch_faces(divisions);
        // Officially, `polyhedron` requires a closed 3D volume, but OpenSCAD
        // will let us preview a single patch even though we won't be able to
        // render it.
        polyhedron(mesh_vertices, faces);
    }

    module half_teapot(facets) {
        // The rim, body, lid, and bottom form one quadrant of the teapot, so we
        // generate each of those patches along with rotated copies to make half
        // the body.
        quarter_patches = [
            each lid_patches,
            each rim_patches,
            each body_patches,
            each bottom_patches
        ];
        for (patch = quarter_patches) {
            divisions = ceil(facets/4);  // each patch represents 1/4
            patch_mesh(patch, divisions);
            rotate([0, 0, -90]) patch_mesh(patch, divisions);
        }

        // The handle and spout are halves.
        for (patch = [each handle_patches, each spout_patches]) {
            divisions = ceil(facets/2);  // each patch represents 1/2
            patch_mesh(patch, divisions);
        }
    }
    
    // This is how OpenSCAD determines the number of facets to generate
    // based on the $fn, $fa, and $fs settings.
    r = 2;  // approximate radius of the widest part of the body.
    facets =
        $fn > 0 ? max(floor($fn), 3) :
        ceil(max(min(360.0 / $fa, 2*PI*r / $fs), 5));

    // For the full teapot, we instantiate half and a mirrored reflection.
    half_teapot(facets);
    mirror([0, 1, 0]) half_teapot(facets);
}

echo($vpr);

teapot($fs=0.2, $fa=1);
color("white") point_cloud(teapot_points);

// The dataset decribes a squashed version of the teapot.  If we scale it
// vertically, we get closer to what the actual Melita teapot looked like.
translate([0, 5, 0]) scale([1, 1, 4/3]) teapot($fn=64);

translate([0, 0, 6]) rotate($vpr)
    scale(1/10) linear_extrude(1)
        text("The Utah Teapot", size=10, halign="center", valign="center");
