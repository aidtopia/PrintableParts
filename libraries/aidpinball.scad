// Library for designing pinball playfields and parts
// Adrian McCarthy 2023-10-29

function inch(x) = x * 25.4;

$fs=0.2;

playfield_w = inch(20);
playfield_l = inch(42);
playfield_th = inch(1/2);

post_r1 = inch(0.7)/2;
post_r2 = inch(0.4)/2;
post_h = inch(1+1/16);
post_screw_d = inch(0.1495);  // free fit diameter for #6 bolt
post_band_h = inch(0.7);
post_band_th = inch(1/4);
post_band_r = post_r2+post_band_th/4;

function get_post_band_r() = post_band_r;

flipper_d1 = 15;
flipper_d2 = 5;
flipper_l = 61;
flipper_h = 24;
flipper_band_th = 4;
flipper_band_h = flipper_h/2;
flipper_rod_d = 6;

module post() {
    color("red")
    rotate_extrude(angle=360, convexity=4) {
        difference() {
            polygon([
                [post_screw_d/2, 0],
                [post_r1, 0],
                [post_r2, post_band_h],
                [post_r2, post_h],
                [post_screw_d/2, post_h]
            ]);
            translate([post_r2+post_band_th/4, post_band_h])
                circle(d=post_band_th);
        }
    }
//    color("white")
//    rotate_extrude(angle=360, convexity=4) {
//        translate([post_band_r, post_band_h])
//            circle(d=post_band_th);
//    }
}

module post_cutout() {
    circle(d=post_screw_d);
}

module post_with_cutout() {
    post();
    color("black")
    translate([0, 0, -playfield_th-1])
        linear_extrude(playfield_th+1)
            post_cutout();
}

module flipper() {
    module bat_shape() {
        hull () {
            circle(d=flipper_d1);
            translate([flipper_l, 0]) circle(d=flipper_d2);
        }
    }

    translate([0, 0, flipper_h/2 + 1]) {
        color("white")
        linear_extrude(flipper_h, center=true, convexity=8) {
            bat_shape();
        }
        color("blue")
        linear_extrude(flipper_band_h, center=true, convexity=8) {
            offset(r=flipper_band_th) bat_shape();
        }
    }
}

module flipper_cutout() {
    circle(d=flipper_rod_d);
}

module flipper_with_cutout() {
    flipper();
    color("black")
    translate([0, 0, -playfield_th-1])
        linear_extrude(playfield_th+2)
            flipper_cutout();
}

posts = [
    [playfield_w/2 - inch(3), inch(18)],
    [playfield_w/2, inch(20)],
    [playfield_w/2, inch(24)]
];

flippers = [
    [playfield_w/2 - inch(3.5), inch(6), -30],
    [playfield_w/2 + inch(3.5), inch(6), -150]
];

module playfield() {
    difference() {
        translate([0, 0, -playfield_th])
            linear_extrude(playfield_th, convexity=10)
                square([playfield_w, playfield_l]);
        children();
    }
    children();
}

// Computes the dot product of two 2D vectors.
function dot(v1, v2) = v1.x*v2.x + v1.y*v2.y;

// Finds the first point on the perimeter of the convex hull of the 2D points.
// Chooses the lowest (minimum y).  If that's ambiguous, it chooses the
// leftmost of those.
function first_hull_point(points) =
    let (
        count = len(points)
    ) 
    count == 1 ? points[0] :
    count == 2 ?
        (points[0].y < points[1].y) ? points[0] :
        (points[0].y > points[1].y) ? points[1] :
        (points[0].x < points[1].x) ? points[0] : points[1]
    :
        let (
            mid = floor(count/2),
            r1 = first_hull_point([for (i=[0:mid]) points[i]]),
            r2 = first_hull_point([for (i=[mid+1:count-1]) points[i]])
        )
        r1.y < r2.y ? r1 :
        r1.y > r2.y ? r2 :
        r1.x < r2.x ? r1 : r2;

// Computes the dot products between v1 and a vector from current to
// each candidates.  Returns a list of [candidate, dot] pairs.
function compute_dots(v1, current, candidates) =
    [for (candidate=candidates)
        let (
            delta = candidate - current,
            mag = norm(delta),
            v2 = mag > 0 ? delta / norm(delta) : [0, 0]
        )
        [candidate, dot(v1, v2)]
    ];

// Given a list of pairs [a, b], returns the one with the largest b.
function maxdot(dotted) =
    let (
        count = len(dotted)
    )
    count == 1 ? dotted[0] :
    count == 2 ? dotted[0][1] > dotted[1][1] ? dotted[0] : dotted[1] :
    let (
        mid = floor(count/2),
        r1 = maxdot([for (i=[0:mid]) dotted[i]]),
        r2 = maxdot([for (i=[mid+1:count-1]) dotted[i]])
    )
    r1[1] > r2[1] ? r1 : r2;

// Accepts a pair of lists [[first], [points]] and returns a modified pair
// where the next point in points on the convex hull of all the points
// is removed from points and appended to first.
function complete_hull(context) =
    let (
        perimeter = context[0],
        candidates = context[1],
        count = len(candidates)
    )
    count == 0 ?
        [perimeter, []] :
    count == 1 ?
        candidates[0] != perimeter[0] ?
            [[each perimeter, candidates[0]], []] :
            [perimeter, candidates]
    :
        let (
            h = len(perimeter),
            current = perimeter[h-1],
            v1 = h > 1 ? perimeter[h-1] - perimeter[h-2] : [1, 0, 0],
            dotted = compute_dots(v1, current, candidates),
            next = maxdot(dotted)[0]
        )
        next == perimeter[0] ? [perimeter, candidates] :
        complete_hull([
            [each perimeter, next],
            [for (candidate=candidates) if (candidate != next) candidate]
        ]);

// Given and unordered list of post locations, returns a list of the ones
// on the convex hull, in counterclockwise order.
function order_posts(positions) =
    complete_hull([[first_hull_point(positions)], positions])[0];

// Current limitation: assumes positions include just the posts that
// form the convex hull around the group and that they're listed in
// counterclockwise order.
module band_posts(positions) {
    module straight(P0, P1) {
        delta = P1 - P0;
        length = norm(delta);
        unit = delta/length;
        dir = atan2(unit.y, unit.x);  // yes, y before x
        // nudge moves the leg perpendicularly away from the line
        // between the posts, assuming P0->P1 moves counterclockwise
        // around the convext hull.
        nudge = -post_band_r * cross([0, 0, 1], [unit.x, unit.y, 0]); 
        
        translate(nudge + P0) rotate([0, 90, dir]) {
            linear_extrude(length) circle(d=post_band_th);
        }
    }

    module slice(A0, A1) {
        rotate([0, 0, A0]) {
            rotate_extrude(angle=A1-A0, convexity=4) {
                translate([post_band_r, 0])
                    circle(d=post_band_th);
            }
        }
    }
    
    module bend_around(P, previous, next) {
        delta0 = previous - P;
        angle0 = atan2(delta0.y, delta0.x);
        start_angle = angle0 + 90;
        delta1 = next - P;
        angle1 = atan2(delta1.y, delta1.x);
        temp_end_angle = angle1 - 90;
        end_angle = temp_end_angle < 0 ? temp_end_angle + 360 : temp_end_angle;
        A0 = start_angle <    0 ? start_angle + 360 :
             start_angle >= 360 ? start_angle - 360 :
                                  start_angle;
        A1 = end_angle < A0 ? end_angle + 360 : end_angle;
        translate(P) slice(A0, A1);
    }
    
    perimeter = order_posts(positions);
    translate([0, 0, post_band_h]) {
        count = len(perimeter);
        if (count >= 2) {
            for (i=[1:count]) {
                straight(perimeter[i - 1], perimeter[i%count]);
            }
        }
        
        if (count == 1) {
            translate(perimeter[0]) slice(0, 360);
        }
        if (count >= 2) {
            for (i=[1:count-1]) {
                bend_around(perimeter[i], perimeter[i-1], perimeter[(i+1) % count]);
            }
            bend_around(perimeter[0], perimeter[count-1], perimeter[1]);
        }
    }
}

// The plastic piece over a banded set of posts, like the top of a slingshot.
module playfield_plastic(posts, th=3) {
    r = post_band_r + 0.5*post_band_th;
    translate([0, 0, post_h]) linear_extrude(th) {
        if (len(posts) >= 3) {
            offset(r=post_band_r + 0.5*post_band_th)
                polygon(posts);
        } else {
            hull() for (p=posts) translate(p) circle(r=r);
        }
    }
}

playfield() {
    translate(posts[0]) post_with_cutout();
    translate(posts[1]) post_with_cutout();
    translate(posts[2]) post_with_cutout();
    translate([flippers[0].x, flippers[0].y])
        rotate([0, 0, flippers[0].z])
            flipper_with_cutout();
    translate([flippers[1].x, flippers[1].y])
        rotate([0, 0, flippers[1].z])
            flipper_with_cutout();
}

