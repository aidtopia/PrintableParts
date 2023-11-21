// Hacks in OpenSCAD
// Adrian McCarthy 2023

// There's no good way to do this in OpenSCAD.  This hack will draw
// your text at the desired size.  This works by placing individual
// "bricks" that don't quite touch.  I'm working on that.
module AX_text_on_curved_baseline(string, size=10, baseline_r=30) {
    facet_size = max($fs, size/50, 0.4) * ($preview ? 2 : 1);

    function lerp(x, y0, y1) = y0 + x*(y1 - y0);
    function circumference(r) = 2*PI*r;

    module texture() {
        text(string, size=size, halign="center", valign="baseline");
    }
    
    module sample(x, y) {
        translate([-x, -y]) {
            intersection() {
                texture();
                translate([x, y]) square(facet_size, center=true);
            }
        }
    }
    
    top_r = baseline_r + size;
    bottom_r = baseline_r - size;
    approx_w = 0.75*len(string)*size;
    total_h = top_r - bottom_r;
    sweep = approx_w / circumference(baseline_r) * 360;
    assert(0 < sweep && sweep < 360);
    theta0 =  sweep/2;
    theta1 = -sweep/2;

    v_max = total_h/facet_size;
    for (v=[0:1.1:v_max]) {
        r = lerp(v/v_max, bottom_r, top_r);
        y = lerp(v/v_max, -size, size);

        sweep_circum_at_r = sweep/360 * circumference(r);
        u_max = sweep_circum_at_r / facet_size;
        for (u=[0:1.1:u_max]) {
            theta = lerp(u/u_max, theta0, theta1);
            x = lerp(u/u_max, -approx_w/2, approx_w/2);
            rotate([0, 0, theta]) translate([0, r]) sample(x, y);
        }
    }
}


module AX_Demo() {
    $fs = 1;
    $fa = 3;
    linear_extrude(1, convexity=10)
            AX_text_on_curved_baseline("Welcome to the Thunderdome", size=10, baseline_r=40);
}

AX_Demo();
