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
function eround(x) = epsilon * round(x/epsilon);
function eceil(x) = epsilon * ceil(x/epsilon);
function efloor(x) = epsilon * floor(x/epsilon);

$fa = 15;
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
    wide ? max(sleeve[0], sleeve[1]) : min(sleeve[0], sleeve[1]),
    wide ? min(sleeve[0], sleeve[1]) : max(sleeve[0], sleeve[1]),
    n*(quality+card)];

// basic metrics
wall0 = xwall(4);
floor0 = qlayer(wall0);
gap0 = 0.1;

function unit_axis(n) = [for (i=[0:1:2]) i==n ? 1 : 0];
function diag2(x, y) = sqrt(x*x + y*y);
function diag3(x, y, z) = sqrt(x*x + y*y + z*z);

// utility modules
module raise(z=floor0) {
    translate([0, 0, z]) children();
}
module rounded_square(r, size) {
    offset(r=r) offset(r=-r) square(size, center=true);
}
module stadium(size) {
    if (is_list(size)) {
        hull() {
            if (size[0] < size[1]) {
                d = size[0];
                a = [d, size[1]-d];
                for (i=[-1,+1]) translate([0, i*a[1]/2]) circle(d=d);
            } else {
                d = size[1];
                a = [size[0]-d, d];
                for (i=[-1,+1]) translate([i*a[0]/2, 0]) circle(d=d);
            }
        }
    } else stadium([size, size]);
}

module tongue(size, h=floor0, a=60, groove=false, gap=gap0) {
    // groove = false: positive image. gap is inset from the bounding box.
    // groove = true: negative image. gap is extended above top and below base.
    top = size - (groove ? 0 : 1) * [gap, gap];
    rise = flayer(h/2);
    run = rise / tan(a);
    base = top + 2*[run, run];
    hull() {
        linear_extrude(h) stadium(top);
        linear_extrude(h - rise) stadium(base);
    }
    if (groove) {
        linear_extrude(h+gap) stadium(top);
        linear_extrude(2*gap, center=true) stadium(base);
    }
}


// box metrics
Vinterior = [288, 288, 69];  // box interior
Hwrap0 = 53;  // cover art wrap ends here
Hwrap1 = 56;  // avoid stacks between 53-56mm total height
module box(size, wall=1, frame=false, a=0) {
    vint = is_list(size) ? size : [size, size, size];
    vext = [vint[0] + 2*wall, vint[1] + 2*wall, vint[2] + wall];
    vcut = [vint[0], vint[1], vint[2] - wall];
    origin = [0, 0, vext[2]/2 - wall];
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
        raise(Hwrap0 + wall-vext[2]/2)
            linear_extrude(Hwrap1-Hwrap0) difference() {
            square([vint[0]+wall, vint[1]+wall], center=true);
            square([vint[0], vint[1]], center=true);
        }
    }
}

// component metrics
Nplayers = 5;
Nmaps = 16;  // number of map and water tiles
Hboard = 2.25;  // tile & token thickness
Rhex = 3/4 * 25.4;  // hex major radius (center to vertex)
Hcap = clayer(4);  // total height of lid + plug
Vfocus5 = [371, 5*Hboard, 21.2];
Vfocus4 = [309, 4*Hboard, 21.6];
Vmanual1 = [8.5*inch, 11*inch, 1.6];  // approximate
Vmanual2 = [7.5*inch, 9.5*inch, 1.6];  // approximate
Hroom = floor(Vinterior[2] - Vmanual1[2] - Vmanual2[2]);
function tier_height(k) = k ? flayer(Hroom/k) : Vinterior[2];
function tier_fit(z) = tier_height(floor(Hroom/z));

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
Dthumb = 25;  // thumb cutout diameter
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
Hshelf4 = Vfocus4[2] + Rint;
Hshelf5 = Vfocus5[2] + Rext;
Vfframe = [for (x=[  // round dimensions to even layers
    diag2(Vinterior[0], Vinterior[1]),
    max(Vfocus4[1], Vfocus5[1]) + 2*Rext - Rint,  // 1mm narrower than usual
    floor0 + Hshelf4 + Hshelf5,
]) qlayer(x)];

module wall_vee_cut(size, a=Avee, gap=gap0) {
    span = size[0];
    y0 = -2*Rext;
    y1 = size[2];
    rise = y1;
    run = rise/tan(a);
    x0 = span/2;
    x1 = x0 + run;
    a1 = (180-a)/2;
    x2 = x1 + Rext/tan(a1);
    x3 = x2 + Rext;
    poly = [[x3, y0], [x3, y1], [x1, y1], [x0, 0], [x0, y0]];
    rotate([90, 0, 0]) linear_extrude(size[1]+2*gap, center=true)
    difference() {
        translate([0, y1/2+gap/2]) square([2*x2, y1+gap], center=true);
        for (s=[-1,+1]) scale([s, 1]) hull() {
            offset(r=Rext) offset(r=-Rext) polygon(poly);
            translate([x0, y0]) square([x3-x0, -y0]);
        }
    }
}

module prism(h, shape=1, r=0, scale=1) {
    // TODO: calculate scale from bounding boxes?
    linear_extrude(h, scale=scale) offset(r=r) offset(r=-r)
    if (is_list(shape) && is_list(shape[0])) {
        polygon(shape);
    } else {
        square(shape, center=true);
    }
}

module focus_bar(v, color=5) {
    k = floor(v[0] / 60);
    module focus(n, cut=false) {
        origin = [-60 * (k+1)/2, 0];
        translate(origin + [60 * n, 0]) if (cut) {
            cube([50, 2*v[1], 12], center=true);
        } else {
            difference() {
                color("tan", 0.5) cube([50, v[1], 12], center=true);
                cube([48, 2*v[1], 10], center=true);
            }
            color("olivedrab", 0.5) cube([48, v[1], 10], center=true);
        }
    }
    difference() {
        color("tan", 0.5) cube(v, center=true);
        cube([k*60, 2*v[1], 16], center=true);
    }
    color(is_num(color) ? player_colors[color] : color, 0.5) difference() {
        cube([k*60, v[1], 16], center=true);
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
    f4wall = qwall((Vfocus5[1] - Vfocus4[1]) / 2 + wall0);
    // well sizes
    f5well = [Vfocus5[0] + 2*Rint, Vfframe[1] - 2*f5wall];
    f4well = [Vfocus4[0] + 2*Rint, Vfframe[1] - 2*f4wall];
    // trestle lattice
    dstrut = 4.8;  // strut width
    rstrut = Rint;
    // space between sections
    xjoint = 40;
    xspan = xspread + xjoint;
    // depth for cutting through Y axis
    dycut = Vfframe[1] + 2*gap0;

    module joiner_tongue(groove=false) {
        d = Vfframe[1]/2;
        top = [xspan + 3*d, d];
        translate([0, Vfframe[1]/2]) tongue(top, groove=groove);
    }
    module lattice(i, j, half=false, tiers=2) {
        // make sure height is evenly divisible by 2, 3, 6 tiers
        hlayers = 6*round(nlayer(Vfframe[2]-dstrut)/6);
        htri = zlayer(hlayers / tiers); // trestle height
        dtri = 2*eround(htri/tan(Avee));  // trestle width (triangle base)
        tfull = [[dtri/2, -htri/2], [0, htri/2], [-dtri/2, -htri/2]];
        thalf = [[0, -htri/2], [0, htri/2], [-dtri/2, -htri/2]];
        xstrut = eround(dstrut/2 / sin(Avee));
        z0 = qlayer(Vfframe[2] - htri*tiers) / 2;
        x0 = eround((z0 - floor0) / tan(Avee)) + xstrut;
        y0 = dycut - gap0;
        origin = [xjoint/2 + x0, y0, z0];
        flip = 1 - (2 * (i % 2));
        translate(origin + [(i+j+1)/2*dtri, 0, (j+1/2)*htri])
            scale([1, 1, flip]) rotate([90, 0, 0]) linear_extrude(dycut)
            offset(r=rstrut) offset(r=-dstrut/2-rstrut)
            polygon(half ? thalf : tfull);
        // TODO: clean this up
        xwell4 = (f4well[0]/2 - origin[0]);
        ntri4 = floor(2*xwell4/dtri)/2;
        otri4 = xwell4 - ntri4*dtri;
        // echo(ntri4, otri4, dtri/2-otri4, xjoint);
    }
    module riser() {
        side = sign(section);
        y0 = 0;
        y1 = Vfframe[1];
        x0 = Vfframe[0]/2 + Rext;
        x1 = x0 - Vfframe[1];
        x2 = x1 - 2*Rext;
        corner = [[x0, y0], [x1, y1], [x2, y1], [x2, y0]];
        color(color) scale([sign(section), 1]) difference() {
            // shell
            linear_extrude(Vfframe[2]) hull() {
                offset(r=Rext) offset(r=-Rext) polygon(corner);
                translate([xjoint/2, 0]) square(y1);
            }
            translate([0, Vfframe[1]/2, floor0]) {
                wall_vee_cut([xjoint, Vfframe[1], Vfframe[2]-floor0]);
                // focus bar wells
                prism(Vfframe[2], f4well, r=Rint);
                raise(Hshelf4) prism(Vfframe[2], f5well, r=Rint);
                // bottom well taper
                hull() {
                    taper = (f5well[1] - f4well[1]) / 2;
                    rise = taper * tan(Avee);
                    htaper = Hshelf4-rise/2;
                    f4top = [f4well[0], f5well[1]];
                    raise(htaper-rise/2) prism(Vfframe[2], f4well, r=Rint);
                    raise(htaper+rise/2) prism(Vfframe[2], f4top, r=Rint);
                }
            }
            // trestle lattice
            for (i=[0:5]) lattice(i, 0, tiers=1);
            *for (i=[12:13]) lattice(i, 1);
            *for (i=[13:14]) lattice(i, 0);
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
            translate([0, Vfframe[1]/2]) linear_extrude(floor0)
                square([xspan-gap0, Vfframe[1]], center=true);
            joiner_tongue();
        }
    } else {
        // combine everything
        focus_frame(+1, color=color);
        focus_frame(-1, color=color);
        color(color) {
            translate([0, Vfframe[1]/2]) linear_extrude(floor0) {
                square([xjoint*3+2*gap0, Vfframe[1]], center=true);
            }
        }
        // ghost focus bars
        %translate([0, Vfframe[1]/2]) raise() {
            raise(Vfocus4[2]/2) focus_bar(Vfocus4);
            raise(Vfocus4[2] + Rint + Vfocus5[2]/2) focus_bar(Vfocus5);
        }
    }
}

function hex_grid(x, y, r=Rhex) = [r*x, sin(60)*r*y];
function hex_points(grid=Ghex, r=Rhex) = [for (i=grid) hex_grid(i[0],i[1],r)];
function hex_min(grid=Ghex, r=Rhex) =
    hex_grid(min([for (i=grid) i[0]]), min([for (i=grid) i[1]]), r);

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
    v[1] + 2*Rext,
    v[2] + 2*Rext,
    v[0] + Rext + floor0]) qlayer(x)];
function card_tray_volume(v) = [for (x=[  // round dimensions to even layers
    v[0] + 2*Rext,
    v[1] + 2*Rext,
    v[2] + Rext + floor0]) qlayer(x)];

// player focus decks: Gamegenic green sleeves
Vdeck = vdeck(29, green_sleeve, premium_sleeve);
Vdbox = deck_box_volume(Vdeck);
module deck_box(v=Vdeck, color=undef) {
    vbox = deck_box_volume(v);
    well = vbox - 2*[wall0, wall0];
    // notch dimensions:
    hvee = qlayer(vbox[2]/2);  // half the height of the box
    dvee = 2*hvee*cos(Avee);  // point of the vee exactly at the base
    vee = [dvee, vbox[1], vbox[2]-hvee];
    color(color) difference() {
        linear_extrude(vbox[2])
            rounded_square(Rext, [vbox[0], vbox[1]]);
        raise() linear_extrude(vbox[2])
            rounded_square(Rint, [well[0], well[1]]);
        raise(hvee) wall_vee_cut(vee);
    }
    %raise(floor0 + Vdeck[0]/2) rotate([0, 90, 90]) cube(Vdeck, center=true);
}

// leader sheets: thick card with Sleeve Kings super large sleeve
Vleaders = vdeck(18, super_large_sleeve, thick_sleeve, leader_card, wide=true);

module card_well(v, gap=gap0) {
    vtray = card_tray_volume(v);
    shell = [vtray[0], vtray[1]];
    well = shell - 2*[wall0, wall0];
    raise() linear_extrude(vtray[2]-floor0+gap)
        rounded_square(Rint, well);
    raise(-gap) linear_extrude(floor0+2*gap) {
        // thumb round
        intersection() {
            translate([0, -vtray[1]/2]) stadium([Dthumb, Dthumb+2*wall0]);
            square(shell + 2*[gap, gap], center=true);
        }
        // bottom hole
        if (3*Dthumb < min(well[0], well[1])) {
            rounded_square(Dthumb/2, well - 2*[Dthumb, Dthumb]);
        } else if (2.5*Dthumb < well[1]) {
            dy = max(Dthumb, well[1] - 2*Dthumb);
            translate([0, Dthumb/4]) stadium([Dthumb, dy]);
        } else if (3.5*Dthumb < well[0]) {
            dx = (well[0]-2*Dthumb)/2;
            dy = (well[1]-2*Dthumb)/4;
            for (i=[-1,+1]) translate([i*dx, dy]) circle(d=Dthumb);
        }
    }
    raise() translate([0, wall0-vtray[1]]/2)
        wall_vee_cut([Dthumb, wall0, vtray[2]-floor0], gap=gap);
}

module card_tray(v, color=undef) {
    // TODO: round height to a simple fraction of Hroom?
    // TODO: round sizes up to convenient multiples (1mm, 5mm, etc)
    vtray = card_tray_volume(v);
    shell = [vtray[0], vtray[1]];
    well = shell - [2*wall0, 2*wall0];
    color(color) difference() {
        linear_extrude(vtray[2]) rounded_square(Rext, shell);
        card_well(v);
    }
    // card stack
    %raise(floor0 + v[2]/2) cube(v, center=true);
}
module leaders_card_tray(color=undef) {
    // TODO: expand this to exactly 135x110mm
    card_tray(Vleaders, color=color);
}

module organizer() {
    // box shape and manuals
    // everything needs to fit inside this!
    %color("#101080", 0.25) box(Vinterior, frame=true);
    *%color("#101080", 0.1) translate([-Vinterior[0]/2, -Vinterior[1]/2]) {
        raise(Vinterior[2]-Vmanual1[2]-Vmanual2[2]) {
            cube(Vmanual1);
            raise(Vmanual2[2]) cube(Vmanual2);
        }
    }
    // focus frame bar and everything below
    rotate(135) translate([0, -Rext]) {
        // focus bars
        focus_frame(color=player_colors[0]);
        translate([0, Vfframe[1]+gap0]) {
            // player deck boxes
            deltadb = [Vdbox[0]+gap0, Vdbox[1]+gap0];
            player = [2, 3, 4, 1, 0, 5];
            translate([0, Vdbox[1]/2])
                for (x=[-1, 0, +1]) for (y=[0, 1])
                translate([x*deltadb[0], y*deltadb[1], 0])
                    deck_box(color=player_colors[player[3*y+x+1]]);
            // map tiles
            ystack = 5*Rhex + 2*Rext;
            translate([0, 2*deltadb[1]+ystack/2]) rotate(-90)
                map_tile_stack(color=player_colors[0]);
        }
    }
    // everything above the bar
    rotate(-45) translate([0, Rext+gap0]) {
        translate([0, card_tray_volume(Vleaders)[1]/2]) rotate(180)
            leaders_card_tray(color=player_colors[0]);
        // TODO: wonders
        // TODO: barbarians
        // TODO: city states
        // TODO: resources
        // TODO: turn this into a working player tray
        points = [
            [[107, 40], 135, 2],
            [[-107, 40], -135, 5],
            [[0, 147.5], 0, 3],
        ];
        echo(card_tray_volume(Vleaders), diag2(Vinterior[0], Vinterior[1])/2);
        for (p=points) translate(p[0]) rotate(p[1]) {
            color(player_colors[p[2]]) translate([0, 18])
                linear_extrude(tier_height(2)) circle(d=50);
            color(player_colors[0])
                linear_extrude(tier_height(2)-Rext) circle(d=75);
            linear_extrude(tier_height(2)-2*Rext) hull() {
                translate([0, 18]) circle(d=50);
                circle(d=75);
                translate([0, -26]) square([135, 23], center=true);
            }
        }
    }
}

// tests for card trays
module test_card_trays() {
    vgreen1 = vdeck(18, green_sleeve, premium_sleeve, wide=false);
    vgreen2 = vdeck(18, green_sleeve, premium_sleeve, wide=true);
    vyellow1 = vdeck(18, yellow_sleeve, premium_sleeve, wide=false);
    vyellow2 = vdeck(18, yellow_sleeve, premium_sleeve, wide=true);
    card_tray(Vleaders);
    translate([90+vgreen1[0]/2, 0]) card_tray(vgreen1);
    translate([0, 75+vgreen2[1]/2]) card_tray(vgreen2);
    translate([-90-vyellow1[0]/2, 0]) card_tray(vyellow1);
    translate([0, -75-vyellow2[1]/2]) card_tray(vyellow2);
    *card_well(Vleaders);

}
*test_card_trays();

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

organizer();
