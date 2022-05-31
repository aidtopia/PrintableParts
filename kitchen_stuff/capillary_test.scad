// Capillary Action Test
// Adrian McCarthy 2022-05-30

module capillaries(ids=[1:10], h=10, wall_th=1) {

    first = ids[0];
    step = ids[1];
    last = ids[2];

    function od(i, range=ids) = i + wall_th;

    function pos(i, range=ids) =
        let (
            first = range[0],
            step  = range[1]
        )
            i < first ? 0 : pos(i-step) + od(i);

    width = pos(last+ step) - od(last)/2 + wall_th;
    depth = od(last) + wall_th;

    for (i = ids) echo(od(i), pos(i));

    difference() {
        union() {
            translate([0, -depth/2, 0]) {
                cube([width, depth, 2*wall_th]);
                translate([-2*wall_th, 0, 0])
                    cube([2*wall_th, depth, h+2*wall_th]);
                translate([width, 0, 0])
                    cube([2*wall_th, depth, h+2*wall_th]);
            }
            for (i = ids)
                translate([pos(i), 0, 0])
                    cylinder(h=h, d=od(i), $fs=0.2);
        }
        for (i = ids)
            translate([pos(i), 0, -1]) cylinder(h=10+2, d=i, $fs=0.2);
    }
}

capillaries([1:0.5:5], h=8);
