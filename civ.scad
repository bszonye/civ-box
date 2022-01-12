echo("\n\n====== CIV ORGANIZER ======\n\n");
layer_height = 0.2;
extrusion_width = 0.45;
extrusion_overlap = layer_height * (1 - PI/4);
extrusion_spacing = extrusion_width - extrusion_overlap;

// convert between path counts and spacing, qspace to quantize
function xspace(n=1) = n*extrusion_spacing;
function nspace(x=xspace()) = x/extrusion_spacing;
function qspace(x=xspace()) = xspace(round(nspace(x)));
function cspace(x=xspace()) = xspace(ceil(nspace(x)));
function fspace(x=xspace()) = xspace(floor(nspace(x)));

// convert between path counts and width, qwall to quantize
function xwall(n=1) = xspace(n) + (0<n ? extrusion_overlap : 0);
function nwall(x=xwall()) =  // first path gets full extrusion width
    x < 0 ? nspace(x) :
    x < extrusion_overlap ? 0 :
    nspace(x - extrusion_overlap);
function qwall(x=xwall()) = xwall(round(nwall(x)));
function cwall(x=xwall()) = xwall(ceil(nwall(x)));
function fwall(x=xwall()) = xwall(floor(nwall(x)));

// quantize thin walls only (less than n paths wide, default for 2 perimeters)
function qthin(x=xwall(), n=4.5) = x < xwall(n) ? qwall(x) : x;
function cthin(x=xwall(), n=4.5) = x < xwall(n) ? cwall(x) : x;
function fthin(x=xwall(), n=4.5) = x < xwall(n) ? fwall(x) : x;

// convert between layer counts and height, qlayer to quantize
function zlayer(n=1) = n*layer_height;
function nlayer(z=zlayer()) = z/layer_height;
// quantize heights
function qlayer(z=zlayer()) = zlayer(round(nlayer(z)));
function clayer(z=zlayer()) = zlayer(ceil(nlayer(z)));
function flayer(z=zlayer()) = zlayer(floor(nlayer(z)));

epsilon = 0.01;
function eround(x, e=epsilon) = e * round(x/e);
function eceil(x, e=epsilon) = e * ceil(x/e);
function efloor(x, e=epsilon) = e * floor(x/e);
function tround(x) = eround(x, e=0.05);  // twentieths of a millimeter
function tceil(x) = eceil(x, e=0.05);  // twentieths of a millimeter
function tfloor(x) = efloor(x, e=0.05);  // twentieths of a millimeter

// tidy measurements
function vround(v) = [tround(v.x), tround(v.y), qlayer(v.z)];
function vceil(v) = [tceil(v.x), tceil(v.y), clayer(v.z)];
function vfloor(v) = [tfloor(v.x), tfloor(v.y), flayer(v.z)];

// fit checker for assertions
// check whether a specified volume (vspec) is sufficiently large to contain
// another volume, either exactly (vexact) or after rounding (vround).
// will echo a summary table if vtrace is set or if the fit fails.
vtrace = true;
function vfit(vspec, vexact, title="vfit") = let (vround = vround(vexact))
    (vtrace && vtrace(title, vexact, vround, vspec)) ||
    (vexact.x <= vspec.x || vround.x <= vspec.x) &&
    (vexact.y <= vspec.y || vround.y <= vspec.y) &&
    (vexact.z <= vspec.z || vround.z <= vspec.z) ||
    (!vtrace && vtrace(title, vexact, vround, vspec));
function vtrace(title, vexact, vround, vspec) =  // returns undef
    echo(title) echo(vspec=vspec) echo(vround=vround) echo(vexact=vexact);

$fa = 15;  // 24 segments per circle (aligns with axes)
$fs = min(layer_height/2, xspace(1)/2);

inch = 25.4;
card = [2.5*inch, 3.5*inch];  // standard playing card dimensions
phi = (1+sqrt(5))/2;

// Gamegenic sleeves
sand_sleeve = [81, 122];  // Dixit
orange_sleeve = [73, 122];  // Tarot
magenta_sleeve = [72, 112];  // Scythe
brown_sleeve = [67, 103];  // 7 Wonders
lime_sleeve = [82, 82];  // Big Square
blue_sleeve = [73, 73];  // Square
dark_blue_sleeve = [53, 53];  // Mini Square
gray_sleeve = [66, 91];  // Standard Card
purple_sleeve = [62, 94];  // Standard European
ruby_sleeve = [46, 71];  // Mini European
green_sleeve = [59, 91];  // Standard American
yellow_sleeve = [44, 67];  // Mini American
catan_sleeve = [56, 82];  // Catan (English)
// Sleeve Kings sleeves
super_large_sleeve = [104, 129];

playing_card = 0.35;  // common unsleeved card thickness (UG assumes 0.325)
leader_card = 0.45;  // thickness of Civilization leader sheets
no_sleeve = 0;
penny_sleeve = 0.08;  // 40 micron sleeves (Mayday)
thick_sleeve = 0.12;  // 60 micron sleeves (Sleeve Kings)
premium_sleeve = 0.2;  // 100 micron sleeves (Gamegenic)
double_sleeve = 0.3;  // premium sleeve + inner sleeve
function card_count(h, quality=no_sleeve, card=playing_card) =
    floor(d / (card + quality));
function vdeck(n=1, sleeve, quality, card=playing_card, wide=false) = [
    wide ? max(sleeve.x, sleeve.y) : min(sleeve.x, sleeve.y),
    wide ? min(sleeve.x, sleeve.y) : max(sleeve.x, sleeve.y),
    n*(quality+card)];

// basic metrics
wall0 = xwall(4);
floor0 = qlayer(wall0);
gap0 = 0.1;

function unit_axis(n) = [for (i=[0:1:2]) i==n ? 1 : 0];

// utility modules
module raise(z=floor0) {
    translate([0, 0, z]) children();
}
module rounded_square(r, size) {
    offset(r=r) offset(r=-r) square(size, center=true);
}
module stadium(side, r=undef, d=undef, a=0) {
    radius = is_undef(d) ? r : d/2;
    u = [cos(a), sin(a)];
    hull() {
        if (side) rotate(a) square([side, 2*radius], center=true);
        for (i=[-1,+1]) translate(i*u*side/2) circle(radius);
    }
}
module stadium_fill(size) {
    if (is_list(size)) {
        if (size.x < size.y) stadium(size.y - size.x, d=size.x, a=90);
        else if (size.y < size.x) stadium(size.x - size.y, d=size.y);
        else circle(d=size.x);
    } else stadium_fill([size, size]);
}
module semistadium(side, r=undef, d=undef, a=0, center=false) {
    radius = is_undef(d) ? r : d/2;
    angle = a+90;  // default orientation is up
    u = [cos(angle), sin(angle)];
    translate(center ? -u*(side+radius)/2 : [0, 0]) hull() {
        rotate(angle) translate([side/2, 0])
            square([max(side, epsilon), 2*radius], center=true);
        translate(u*side) intersection() {
            circle(radius);
            rotate(angle) translate([radius, 0]) square(2*radius, center=true);
        }
    }
}
module semistadium_fill(size, center=false) {
    if (is_list(size)) {
        if (size.y < size.x)
            semistadium(size.x - size.y/2, d=size.y, a=-90, center=center);
        else
            semistadium(size.y - size.x/2, d=size.x, center=center);
    } else semistadium_fill([size, size], center=center);
}

module tongue(size, h=floor0, a=60, groove=false, gap=gap0) {
    // groove = false: positive image. gap is inset from the bounding box.
    // groove = true: negative image. gap is extended above top and below base.
    top = size - (groove ? 0 : 1) * [gap, gap];
    rise = flayer(h/2);
    run = rise / tan(a);
    base = top + 2*[run, run];
    hull() {
        linear_extrude(h) stadium_fill(top);
        linear_extrude(h - rise) stadium_fill(base);
    }
    if (groove) {
        linear_extrude(h+gap) stadium_fill(top);
        linear_extrude(2*gap, center=true) stadium_fill(base);
    }
}


// box metrics
Vinterior = [288, 288, 69];  // box interior
Hwrap0 = 53;  // cover art wrap ends here
Hwrap1 = 56;  // avoid stacks between 53-56mm total height
module box(size, wall=1, frame=false, a=0) {
    vint = is_list(size) ? size : [size, size, size];
    vext = [vint.x + 2*wall, vint.y + 2*wall, vint.z + wall];
    vcut = [vint.x, vint.y, vint.z - wall];
    origin = [0, 0, vext.z/2 - wall];
    translate(origin) rotate(a) {
        difference() {
            cube(vext, center=true);  // exterior
            raise(wall/2) cube(vint, center=true);  // interior
            raise(2*wall) cube(vcut, center=true);  // top cut
            if (frame) {
                for (n=[0:2]) for (i=[-1,+1])
                    translate(2*i*unit_axis(n)*wall) cube(vcut, center=true);
            }
        }
        raise(Hwrap0 + wall-vext.z/2)
            linear_extrude(Hwrap1-Hwrap0) difference() {
            square([vint.x+wall, vint.y+wall], center=true);
            square([vint.x, vint.y], center=true);
        }
    }
}

// component metrics
Nplayers = 5;
Nmaps = 16;  // number of map and water tiles
Hboard = 2.25;  // tile & token thickness
Rhex = 3/4 * 25.4;  // hex major radius (center to vertex)
Rhex1 = 18;  // radius of single hex tiles
Hcap = clayer(4);  // total height of lid + plug
Vfocus5 = [371, 5*Hboard, 21.2];
Vfocus4 = [309, 4*Hboard, 21.6];
Vmanual1 = [8.5*inch, 11*inch, 1.6];  // approximate
Vmanual2 = [7.5*inch, 9.5*inch, 1.6];  // approximate
Hroom = ceil(Vinterior.z - Vmanual1.z - Vmanual2.z) - 1;
function tier_height(k) = k ? flayer(Hroom/k) : Vinterior.z;
function tier_number(z) = floor(Hroom/z);
function tier_ceil(z) = tier_height(tier_number(z));
function tier_room(z) = tier_ceil(z) - z;

Ghex = [[1, 0], [0.5, 1], [-0.5, 1], [-1, 0], [-0.5, -1], [0.5, -1]];
Gmap = [
    [2.5, 0], [2, 1], [2.5, 2], [2, 3], [2.5, 4], [2, 5],
    [1, 5], [0.5, 4], [-0.5, 4], [-1, 3], [-0.5, 2],
    [-1, 1], [-2, 1], [-2.5, 0], [-2, -1], [-2.5, -2],
    [-2, -3], [-1, -3], [-0.5, -4], [0.5, -4], [1, -3],
    [2, -3], [2.5, -2], [2, -1],
];

player_colors = [
    "#600020",
    "crimson",
    "darkorange",
    "springgreen",
    "aqua",
    "mediumpurple",
];

// container metrics
Hlid = floor0;  // height of cap lid
Hplug = Hcap - Hlid;  // depth of lid below cap
Rint = 1;  // internal corner radius (distance from contents to wall)
Rext = Rint+wall0;  // external corner radius
Rplug = Rint-gap0;  // internal plug radius (small gap to wall interior)
Alid = 30;  // angle of lid chamfer
Hseam = wall0/2 * tan(Alid) - zlayer(1/2);  // space between lid cap and box
Hchamfer = (Rext-Rplug) * tan(Alid);
Dthumb = 25;  // index hole diameter
Gbox = [
    [2.5, 0], [2, 1], [2.5, 2], [2, 3], [2.5, 4], [2, 5],
    [1, 5], [0.5, 4], [-0.5, 4], [-1, 3], [-2, 3],
    [-2.5, 2], [-2, 1], [-2.5, 0], [-2, -1], [-2.5, -2],
    [-2, -3], [-1, -3], [-0.5, -4], [0.5, -4], [1, -5],
    [2, -5], [2.5, -4], [2, -3], [2.5, -2], [2, -1],
];
Ghole = [
    [1.5, -4], [1.5, -2], [1.5, 0], [1.5, 2], [1.5, 4],
    [0, -3], [0, -1], [0, 1], [0, 3], [-1.5, -2], [-1.5, 0], [-1.5, 2],
];

Avee = 65;
Hshelf4 = Vfocus4.z + Rint;
Hshelf5 = Vfocus5.z + Rext;
Vfframe = [for (x=[  // round dimensions to even layers
    norm([Vinterior.x, Vinterior.y]),  // diagonal length
    max(Vfocus4.y, Vfocus5.y) + 2*Rext - Rint,  // 1mm narrower than usual
    floor0 + Hshelf4 + Hshelf5,
]) qlayer(x)];

module prism(h, shape=1, r=0, scale=1) {
    // TODO: calculate scale from bounding boxes?
    linear_extrude(h, scale=scale) offset(r=r) offset(r=-r)
    if (is_list(shape) && is_list(shape[0])) {
        polygon(shape);
    } else {
        square(shape, center=true);
    }
}

module lattice_cut(v, i, j=0, h0=0, d=4.8, a=Avee, r=Rint,
                   half=0, tiers=1, factors=2) {
    // v: lattice volume
    // i: horizontal position
    // j: vertical position
    // h0: z intercept of pattern start (e.g. floor0 with wall_vee_cut)
    // d: strut width
    // a: strut angle
    // r: corner radius
    // half: -1 = left half, 0 = whole, +1 = right half
    // tiers: number of tiers in vertical split
    // factors: verticial divisibility (use 6/12/etc for complex patterns)
    hlayers = factors*round(nlayer(v.z-d)/factors);
    htri = zlayer(hlayers / tiers); // trestle height
    dtri = 2*eround(htri/tan(a));  // trestle width (triangle base)
    dycut = v.y + 2*gap0; // depth for cutting through Y axis
    tri = [
        [[0, -htri/2], [0, htri/2], [-dtri/2, -htri/2]],  // left
        [[dtri/2, -htri/2], [0, htri/2], [-dtri/2, -htri/2]],  // whole
        [[0, -htri/2], [0, htri/2], [dtri/2, -htri/2]],  // half
    ];
    xstrut = eround(d/2/sin(a));
    flip = 1 - (2 * (i % 2));
    z0 = qlayer(v.z - htri*tiers) / 2;
    x0 = eround((z0 - h0) / tan(a)) + xstrut;
    y0 = dycut - gap0;
    translate([x0, y0, z0] + [(i+j+1)/2*dtri, 0, (j+1/2)*htri])
        scale([1, 1, flip]) rotate([90, 0, 0]) linear_extrude(dycut)
        offset(r=r) offset(r=-d/2-r) polygon(tri[sign(half)+1]);
}
module wall_vee_cut(size, a=Avee, gap=gap0) {
    span = size.x;
    y0 = -2*Rext;
    y1 = size.z;
    rise = y1;
    run = a == 90 ? 0 : rise/tan(a);
    x0 = span/2;
    x1 = x0 + run;
    a1 = (180-a)/2;
    x2 = x1 + Rext/tan(a1);
    x3 = x2 + Rext + epsilon;  // needs +epsilon for 90-degree angles
    poly = [[x3, y0], [x3, y1], [x1, y1], [x0, 0], [x0, y0]];
    rotate([90, 0, 0]) linear_extrude(size.y+2*gap, center=true)
    difference() {
        translate([0, y1/2+gap/2]) square([2*x2, y1+gap], center=true);
        for (s=[-1,+1]) scale([s, 1]) hull() {
            offset(r=Rext) offset(r=-Rext) polygon(poly);
            translate([x0, y0]) square([x3-x0, -y0]);
        }
    }
}

module focus_bar(v, color=5) {
    k = floor(v.x / 60);
    module focus(n, cut=false) {
        origin = [-60 * (k+1)/2, 0];
        translate(origin + [60 * n, 0]) if (cut) {
            cube([50, 2*v.y, 12], center=true);
        } else {
            difference() {
                color("tan", 0.5) cube([50, v.y, 12], center=true);
                cube([48, 2*v.y, 10], center=true);
            }
            color("olivedrab", 0.5) cube([48, v.y, 10], center=true);
        }
    }
    difference() {
        color("tan", 0.5) cube(v, center=true);
        cube([k*60, 2*v.y, 16], center=true);
    }
    color(is_num(color) ? player_colors[color] : color, 0.5) difference() {
        cube([k*60, v.y, 16], center=true);
        for (n=[1:k]) focus(n, cut=true);
    }
    for (n=[1:k]) focus(n);
}

module focus_frame(section=undef, xspread=0, color=undef) {
    // section:
    // undef = whole part
    // -1 = left only
    //  0 = joiner only
    // +1 = right only

    // wall thicknesses
    f5wall = wall0;
    f4wall = qwall((Vfocus5.y - Vfocus4.y) / 2 + wall0);
    // well sizes
    f5well = [Vfocus5.x + 2*Rint, Vfframe.y - 2*f5wall];
    f4well = [Vfocus4.x + 2*Rint, Vfframe.y - 2*f4wall];
    // space between sections
    xjoint = 40;
    xspan = xspread + xjoint;

    module joiner_tongue(groove=false) {
        d = Vfframe.y/2;
        top = [xspan + 3*d, d];
        translate([0, Vfframe.y/2]) tongue(top, groove=groove);
    }
    module riser() {
        side = sign(section);
        y0 = 0;
        y1 = Vfframe.y;
        x0 = Vfframe.x/2 + Rext;
        x1 = x0 - Vfframe.y;
        x2 = x1 - 2*Rext;
        corner = [[x0, y0], [x1, y1], [x2, y1], [x2, y0]];
        color(color) scale([sign(section), 1]) difference() {
            // shell
            linear_extrude(Vfframe.z) hull() {
                offset(r=Rext) offset(r=-Rext) polygon(corner);
                translate([xjoint/2, 0]) square(y1);
            }
            translate([0, Vfframe.y/2, floor0]) {
                wall_vee_cut([xjoint, Vfframe.y, Vfframe.z-floor0]);
                // focus bar wells
                prism(Vfframe.z, f4well, r=Rint);
                raise(Hshelf4) prism(Vfframe.z, f5well, r=Rint);
                // bottom well taper
                hull() {
                    taper = (f5well.y - f4well.y) / 2;
                    rise = taper * tan(Avee);
                    htaper = Hshelf4-rise/2;
                    f4top = [f4well.x, f5well.y];
                    raise(htaper-rise/2) prism(Vfframe.z, f4well, r=Rint);
                    raise(htaper+rise/2) prism(Vfframe.z, f4top, r=Rint);
                }
            }
            // trestle lattice
            translate([xjoint/2, 0]) {
                dstrut=4.8;
                for (i=[0:5]) lattice_cut(Vfframe, i, h0=floor0);
                *for (i=[12:13])
                    lattice_cut(Vfframe, i, 1, h0=floor0, tiers=2);
                *for (i=[13:14])
                    lattice_cut(Vfframe, i, 0, h0=floor0, tiers=2);
            }
            // joiner groove
            joiner_tongue(groove=true);
        }
    }
    if (section) {
        // half riser only
        riser();
    } else if (section == 0) {
        // joiner only
        color(color) {
            translate([0, Vfframe.y/2]) linear_extrude(floor0)
                square([xspan-gap0, Vfframe.y], center=true);
            joiner_tongue();
        }
    } else {
        // combine everything
        focus_frame(+1, color=color);
        focus_frame(-1, color=color);
        color(color) {
            translate([0, Vfframe.y/2]) linear_extrude(floor0) {
                square([xjoint*3+2*gap0, Vfframe.y], center=true);
            }
        }
        // ghost focus bars
        %translate([0, Vfframe.y/2]) raise() {
            raise(Vfocus4.z/2) focus_bar(Vfocus4);
            raise(Vfocus4.z + Rint + Vfocus5.z/2) focus_bar(Vfocus5);
        }
    }
}

function hex_grid(x, y, r=Rhex) = [r*x, sin(60)*r*y];
function hex_points(grid=Ghex, r=Rhex) = [for (i=grid) hex_grid(i.x,i.y,r)];
function hex_min(grid=Ghex, r=Rhex) =
    hex_grid(min([for (i=grid) i.x]), min([for (i=grid) i.y]), r);

module hex_poly(grid=Ghex, r=Rhex) {
    polygon(hex_points(grid, r));
}
module hex_tile(n=1, grid=Ghex, r=Rhex) {
    linear_extrude(Hboard*n) hex_poly(grid=grid, r=r);
}
module hex_lid(grid=Ghex, r=Rhex) {
    xy_min = hex_min(grid, r);
    minkowski() {
        linear_extrude(Hlid, center=false)
            hex_poly(grid=grid, r=r);
        mirror([0, 0, 1]) {
            cylinder(h=Hplug, r=Rplug);
            cylinder(h=Hchamfer, r1=Rext, r2=Rplug);
        }
    }
}

function hex_box_height(n=1, plug=false) =
    clayer(floor0 + n*Hboard + Rint + Hplug) + (plug ? Hplug : 0);
function sum(v) = v ? [for(p=v) 1]*v : 0;
function stack_height(v=[], plug=false, lid=false) =
    sum([for (n=v) hex_box_height(n)]) +  // box heights
    max(0, len(v)-1)*clayer(Hseam) +  // gaps between boxes
    (plug ? Hplug : 0) +  // plug below
    (lid ? sign(len(v))*clayer(Hseam) + Hlid : 0);  // lid above

module hex_box(n=1, plug=false, grid=Ghex, r=Rhex, ghost=undef, color=undef) {
    h = hex_box_height(n=n, plug=false);
    color(color) difference() {
        // exterior
        union() {
            linear_extrude(h, center=false)
                offset(r=Rext) hex_poly(grid=grid, r=r);
            if (plug) hex_lid(grid=grid, r=r);
        }
        // interior
        raise() linear_extrude(h, center=false)
            offset(r=Rext-wall0) hex_poly(grid=grid, r=r);
        // lid chamfer
        raise(h+Hseam) hex_lid(grid=grid);
    }
    // ghost tiles
    %raise(floor0) hex_tile(n=n, grid=(ghost ? ghost : grid), r=r);
}

module map_hex_poly() {
    hex_poly(grid=Ghex);
}
module map_hex(n=1) {
    hex_tile(n=n, grid=Ghex);
}
module map_tile_poly() {
    hex_poly(grid=Gmap);
}
module map_tile(n=1) {
    hex_tile(n=n, grid=Gmap);
}
module map_tile_box(n=Nmaps, plug=false, color=undef) {
    difference() {
        hex_box(n=n, plug=plug, grid=Gbox, ghost=Gmap, color=color);
        for (p=hex_points(Ghole)) translate(p)
            linear_extrude(2*Hcap, center=true)
            offset(r=Rext) offset(r=-Rhex/4-Rext) hex_poly();
    }
}
module map_tile_capitals(color=undef) {
    map_tile_box(n=Nplayers, plug=true, color=color);
}
module map_tile_lid(color=undef) {
    color(color) difference() {
        hex_lid(grid=Gbox);
        for (p=hex_points(Ghole)) translate(p)
            linear_extrude(2*Hcap, center=true)
            offset(r=Rint) offset(delta=-Rhex/4-Rint) hex_poly();
    }
}
module raise_lid(v=[], plug=false) {
    raise(stack_height(v, plug=plug, lid=true) - Hlid) children();
}
module map_tile_stack(color=undef) {
    nmap = 16;
    ncap = 5;
    map_tile_box(nmap, color=color);
    raise_lid([nmap]) {
        map_tile_box(ncap, plug=true, color=color);
        raise_lid([ncap]) map_tile_lid(color=color);
    }
}

function deck_box_volume(v) = [for (x=[  // round dimensions to even layers
    v.y + 2*Rext,
    v.z + 2*Rext,
    v.x + Rext + floor0]) qlayer(x)];
function card_tray_volume(v) = [for (x=[  // round dimensions to even layers
    v.x + 2*Rext,
    v.y + 2*Rext,
    v.z + Rext + floor0]) qlayer(x)];

// player focus decks: Gamegenic green sleeves
Vdeck = vdeck(29, green_sleeve, premium_sleeve);
Vdbox = deck_box_volume(Vdeck);
module deck_box(v=Vdeck, color=undef) {
    vbox = deck_box_volume(v);
    well = vbox - 2*[wall0, wall0];
    // notch dimensions:
    hvee = qlayer(vbox.z/2);  // half the height of the box
    dvee = 2*hvee*cos(Avee);  // point of the vee exactly at the base
    vee = [dvee, vbox.y, vbox.z-hvee];
    color(color) difference() {
        linear_extrude(vbox.z)
            rounded_square(Rext, [vbox.x, vbox.y]);
        raise() linear_extrude(vbox.z)
            rounded_square(Rint, [well.x, well.y]);
        raise(hvee) wall_vee_cut(vee);
    }
    %raise(floor0 + Vdeck.x/2) rotate([0, 90, 90]) cube(Vdeck, center=true);
}

// leader sheets: thick card with Sleeve Kings super large sleeve
Vleaders = vdeck(18, super_large_sleeve, thick_sleeve, leader_card, wide=true);
Vltray = card_tray_volume(Vleaders);

module card_well(v, a=Avee, gap=gap0) {
    vtray = card_tray_volume(v);
    shell = [vtray.x, vtray.y];
    well = shell - 2*[wall0, wall0];
    raise() linear_extrude(vtray.z-floor0+gap)
        rounded_square(Rint, well);
    raise(-gap) linear_extrude(floor0+2*gap) {
        // thumb round
        xthumb = 2/3 * Dthumb;  // depth of thumb round
        translate([0, -gap-vtray.y/2])
            semistadium(xthumb-Dthumb/2+gap, d=Dthumb);
        // bottom index hole
        if (3*Dthumb < min(vtray.x, vtray.y)) {
            // large tray: large, square index hole
            rounded_square(Dthumb/2, vtray - 2*[Dthumb, Dthumb]);
        } else if (3/2*Dthumb+2*xthumb < vtray.y) {
            // medium tray: 1/2 thumb between holes, 2/3 thumb to edge
            dy = vtray.y - 2*xthumb - Dthumb/2;
            translate([0, Dthumb/4]) stadium(dy-Dthumb, d=Dthumb, a=90);
        } else if (3.5*Dthumb < vtray.x) {
            // wide tray: two small holes with balanced margins
            u0 = [0, xthumb-Dthumb/2-vtray.y/2];  // center of thumb round
            u1 = [Dthumb/2, u0.y+Dthumb*sin(60)];
            u2 = [vtray.x/2-Dthumb/2, vtray.y/2-Dthumb/2];  // corner of tray
            t = 1-(1/phi);  // distance from u0 to u1
            ut = t*(u2-u1) + u1;
            for (i=[-1,+1]) translate([i*ut.x, ut.y]) circle(d=Dthumb);
        } else {
            // small tray: long index notch, 1/2 thumb longer than usual
            translate([0, -vtray.y]/2)
                semistadium(xthumb, d=Dthumb);
        }
    }
    raise() translate([0, wall0-vtray.y]/2)
        wall_vee_cut([Dthumb, wall0, vtray.z-floor0], a=a, gap=gap);
}

module card_tray(v, color=undef) {
    // TODO: round height to a simple fraction of Hroom?
    // TODO: round sizes up to convenient multiples (1mm, 5mm, etc)?
    vtray = card_tray_volume(v);
    shell = [vtray.x, vtray.y];
    well = shell - [2*wall0, 2*wall0];
    color(color) difference() {
        linear_extrude(vtray.z) rounded_square(Rext, shell);
        card_well(v);
    }
    // card stack
    %raise(floor0 + v.z/2) cube(v, center=true);
}
module leaders_card_tray(color=undef) {
    // TODO: expand this to exactly 135x110mm?
    card_tray(Vleaders, color=color);
}

Vwonder = [20, 30.35, Hboard];
function wonder_volume(n=3) = [Vwonder.x, Vwonder.y, n*Vwonder.z];
module wonder_tile(n=3) {  // stored in stacks of 3
    linear_extrude(n*Vwonder.z)
        semistadium(Vwonder.y-Vwonder.x/2, d=Vwonder.x);
}
module wonder_well(v, gap=gap0) {
    vtray = v + [2*Rext, 2*Rext, Rext+floor0];
    // well
    raise() linear_extrude(vtray.z-floor0+gap)
        offset(r=Rint) semistadium(v.y-v.x/2, d=v.x);
    // index hole
    margin = 2*Rext + Rint/2;
    dcut = [qlayer(vtray.x-2*margin), vtray.y-margin];
    translate([0, wall0/2-Rext])
        wall_vee_cut([dcut.x, wall0, vtray.z], a=90);
    translate([0, -Rext-gap, -gap]) linear_extrude(floor0+2*gap)
        semistadium(dcut.y-dcut.x/2+gap, d=dcut.x);
}

Vwdeck = vdeck(9, yellow_sleeve, premium_sleeve, wide=true);
Vwtray0 = [
    max(Vwdeck.x, 3*Vwonder.x + 2*Rint) + 2*Rext,
    Vwdeck.y + Rint + Vwonder.y + 3*Rext,
    max(Vwdeck.z, 3*Vwonder.z) + Rext + floor0,
];
Vwtray = vround([72.4, 85, Vwtray0.z]);
assert(vfit(Vwtray, Vwtray0, "WONDERS TRAY"));
module wonders_tray(color=undef) {
    vtray = Vwtray;
    vcards = Vwdeck;
    vtiles = wonder_volume();
    // adjusted card & tile dimensions, including slack
    slack = [
        vtray.x - 2*Rext - vcards.x,
        vtray.y - 3*Rext - vtiles.y - Rint - vcards.y,
    ];
    wcards = [
        vcards.x + slack.x,
        vcards.y + min(slack.y, Rint),
        max(vcards.z, vtiles.z),
    ];
    echo(slack=slack, vcards=vcards, wcards=wcards);
    wtiles = [vtiles.x, vtiles.y, max(vcards.z, vtiles.z)];
    xtile = (vtray.x-wall0)/3 - vtiles.x;  // wonder tile x-spacing
    // xtile = (vtray.x - 2*Rext - 3*vtiles.x) / 2;  // wonder tile x-spacing
    echo(xtile=xtile);
    color(color) difference() {
        prism(vtray.z, [vtray.x, vtray.y], r=Rext);
        // deck well
        translate([0, (vtray.y-wcards.y)/2-Rext]) rotate(180)
            card_well(wcards);
        // wonder tile wells
        for (i=[-1:+1])
            translate([i*(xtile+vtiles.x), Rext-vtray.y/2])
                wonder_well(wtiles);
    }
    %translate([0, (vtray.y-wcards.y)/2-Rext, wcards.z/2+floor0])
        cube(vcards, center=true);
    %for (i=[-1:+1])
        translate([i*(xtile+vtiles.x), Rext-vtray.y/2, floor0])
        wonder_tile();
}

Vcdeck = vdeck(4, yellow_sleeve, premium_sleeve);
Vctray0 = [  // exact size
    3 * (Vcdeck.x + Rint + Rext) + wall0,
    1 * (Vcdeck.y + Rint + Rext) + wall0,
    Vcdeck.z + max(Hboard + Rint, Rext) + floor0,
];
Vctray = vround([145, 85, Vctray0.z]);
assert(vfit(Vctray, Vctray0, "CITY STATES TRAY"));
tier_info("city states", Vctray);
tier_info("city states stack", [Vctray.x, Vctray.y, 2*Vctray.z]);
module city_states_tray(color=undef) {
    vtray = Vctray;
    vcards = Vcdeck;
    wcards = [(vtray.x-wall0)/3-Rint-Rext, vcards.y, vcards.z+Hboard];
    xwell = (vtray.x-wall0)/3-vcards.x;
    echo(xwell=xwell, vcards=vcards, wcards=wcards);
    ahex = 90;
    xhex = Rhex1*cos(abs(ahex % 60));
    yhex = Rhex1*cos(abs(ahex % 60) - 30);
    echo(ahex=ahex, xhex=xhex, yhex=yhex);
    color(color) difference() {
        prism(vtray.z, [vtray.x, vtray.y], r=Rext);
        for (i=[-1:+1]) translate([i*(xwell+vcards.x), 0]) {
            translate([0, (wcards.y-vtray.y)/2+Rext]) card_well(wcards);
            translate([wcards.x/2-xhex, vtray.y/2-yhex-Rext, floor0])
                rotate(ahex) linear_extrude(vtray.z)
                    offset(r=Rint) hex_poly(r=Rhex1);
        }
    }
    %for (i=[-1:+1]) translate([i*(xwell+wcards.x), 0, floor0]) {
        translate([0, (wcards.y-vtray.y)/2+Rext, vcards.z/2])
            cube(vcards, center=true);
        translate([wcards.x/2-xhex, vtray.y/2-yhex-Rext, vcards.z])
            rotate(ahex) hex_tile(r=Rhex1);
    }
}

module tier_info(name, v) {
    h = v.z;
    echo(name);
    echo(v=v, h=h, n=tier_number(h), c=tier_ceil(h), r=tier_room(h));
}

module organizer() {
    // box shape and manuals
    // everything needs to fit inside this!
    %color("#101080", 0.25) box(Vinterior, frame=true);
    %color("#101080", 0.05) translate([-Vinterior.x/2, -Vinterior.y/2]) {
        raise(Hroom) {
            cube(Vmanual1);
            raise(Vmanual2.z) cube(Vmanual2);
        }
    }
    // focus frame bar and everything below
    rotate(135) translate([0, -Rext]) {
        // common deck boxes
        rotate(-45)  // unique focus cards & victory cards
            translate([Vdbox.x/4, Vinterior.y/2-Vdbox.y/2+Rext*cos(45)])
            deck_box(color=player_colors[0]);
        rotate(45)  // pre-expansion cards
            translate([-Vdbox.x/4, Vinterior.y/2-Vdbox.y/2+Rext*cos(45)])
            deck_box(color="#202020");
        // focus bars
        focus_frame(color=player_colors[0]);
        translate([0, Vfframe.y+gap0]) {
            // player deck boxes
            deltadb = [Vdbox.x+gap0, Vdbox.y+gap0];
            translate([0, Vdbox.y/2]) for (player=[1:5])
                for (x=[-1, 0, +1]) for (y=[0, 1])
                translate([(3-player)/2*deltadb.x, (1-player%2)*deltadb.y, 0])
                    deck_box(color=player_colors[player]);
            // map tiles
            ystack = 5*Rhex + 2*Rext;
            translate([0, 2*deltadb.y+ystack/2]) rotate(-90)
                map_tile_stack(color=player_colors[0]);
        }
    }
    // everything above the bar
    rotate(-45) translate([0, Rext+gap0]) {
        tier_info("wonders", Vwtray);
        tier_info("wonders stack",
            [2*Vwtray.x+gap0, Vwtray.y, 2*Vwtray.z]);
        tier_info("leaders", Vltray);
        tier_info("deck box", Vdbox);
        // wonder trays
        for (i=[-1,+1]) for (j=[0,1])
            translate([i*(gap0+Vwtray.x)/2, Vwtray.y/2, j*Vwtray.z])
                wonders_tray();
        // city states
        raise(2 * Vwtray.z)
        for (j=[0,1]) translate([0, Vctray.y/2, j*Vctray.z]) rotate(180)
            city_states_tray();
        // leader tray
        *raise(3*tier_height(4))
            translate([0, card_tray_volume(Vleaders).y/2]) rotate(180)
            leaders_card_tray(color=player_colors[0]);
        // TODO: barbarians
        // TODO: resources
        // TODO: turn this into a working player tray
        x4 = 145;
        y4 = 110;
        x5 = 145;
        // y5 = (y4 - x4/2) * cos(45)/(1-cos(45));
        y5 = 90;  // this one fits, but it's uneven
        echo(x5=x5, y5=y5, y5-x5/2, cos(45) * (y4 + y5 - x4/2));
        pentabox = [
            [x5/2, -y5],
            [x5/2, -x5/2],
            [0, 0],
            [-x5/2, -x5/2],
            [-x5/2, -y5],
        ];
        points = [
            [[x4/2+gap0, 0], 135, 2],
            [[-(x4/2+gap0), 0], -135, 5],
            [[0, y4+y5], 0, 3],
            // [[0, Vwtray.y+gap0 + y5], 0, 3],
        ];
        for (p=points) translate(p[0]) rotate(p[1]) {
            prism(tier_height(2), pentabox, r=Rext);
            *color(player_colors[p[2]]) translate([0, 18])
                linear_extrude(tier_height(2)) circle(d=50);
            *color(player_colors[0])
                linear_extrude(tier_height(2)-Rext) circle(d=75);
            *linear_extrude(tier_height(2)-2*Rext) hull() {
                translate([0, 18]) circle(d=50);
                circle(d=75);
                translate([0, -26]) square([135, 23], center=true);
            }
        }
    }
}

// tests for card trays
module test_trays() {
    vgreen1 = vdeck(18, green_sleeve, premium_sleeve, wide=false);
    vgreen2 = vdeck(18, green_sleeve, premium_sleeve, wide=true);
    vyellow1 = vdeck(18, yellow_sleeve, premium_sleeve, wide=false);
    vyellow2 = vdeck(18, yellow_sleeve, premium_sleeve, wide=true);
    card_tray(Vleaders);
    translate([90+vgreen1.x/2, 0]) card_tray(vgreen1);
    translate([0, 75+vgreen2.y/2]) card_tray(vgreen2);
    translate([-90-vyellow1.x/2, 0]) card_tray(vyellow1);
    translate([0, -75-vyellow2.y/2]) card_tray(vyellow2);
    translate([10+Rext+vyellow2.x/2, -95-vyellow2.y]) {
        translate([10+Vwtray.x/2, -Vwtray.y/2]) wonders_tray();
        translate([-10-Vctray.x/2, -Vctray.y/2]) city_states_tray();
    }
}

*focus_frame();
*focus_frame(+1);
*focus_frame(-1);
*focus_frame(0);
*focus_frame(0, xspread=3);
*raise(-floor0-gap0) focus_frame(0);
*map_tile_box();
*map_tile_capitals();
*map_tile_lid();
*deck_box();
*leaders_card_tray();
*wonders_tray();
*city_states_tray();

*test_trays();
rotate(45) organizer();
