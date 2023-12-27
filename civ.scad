echo("\n\n====== CIV ORGANIZER ======\n\n");

$fa = 15;  // 24 segments per circle (aligns with axes)
$fs = 0.1;

inch = 25.4;
phi = (1+sqrt(5))/2;

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
// * vspec: desired volume specification
// * vxmin: exact minimum size from calculations or measurements
// * vsmin: soft minimum = vround(vxmin)
// true if vspec is larger than either minimum, in all dimensions.
// logs its parameters if vtrace is true or the comparison fails.
vtrace = true;
function vfit(vspec, vxmin, title="vfit") = let (vsmin = vround(vxmin))
    (vtrace && vtrace(title, vxmin, vsmin, vspec)) ||
    (vxmin.x <= vspec.x || vsmin.x <= vspec.x) &&
    (vxmin.y <= vspec.y || vsmin.y <= vspec.y) &&
    (vxmin.z <= vspec.z || vsmin.z <= vspec.z) ||
    (!vtrace && vtrace(title, vxmin, vsmin, vspec));
function vtrace(title, vxmin, vsmin, vspec) =  // returns undef
    echo(title) echo(vspec=vspec) echo(vsmin=vsmin) echo(vxmin=vxmin)
    echo(inch=[for (i=vspec) eround(i/inch)]);

// card dimensions
card = [2.5*inch, 3.5*inch];  // standard playing card dimensions
playing_card = 0.35;  // common unsleeved card thickness (UG assumes 0.325)
leader_card = 0.45;  // thickness of Civilization leader sheets
// TODO: improve card & sleeve measurements
// TODO: account for card float with & without sleeves
// measured (tight-loose)
// 7.0-7.5mm per 24 = 292-313 microns per card
// 10.0-11.0mm per 24 with Sleeve Kings = 417-458 microns per card
// note that the loose measurement has more float with sleeves on!
echo(7.0/24, 7.3/24, 7.5/24, 3.0/24, 0.12*24);
echo(10/24, 11/24);
echo(458-125);

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

// sleeve thickness
no_sleeve = 0;
md_standard = 0.08;  // 40 micron sleeves (Mayday standard)
ug_classic = 0.08;  // 40 micron sleeves (Ultimate Guard classic)
ug_premium = 0.10;  // 50 micron sleeves (Ultimate Guard premium soft)
sk_standard = 0.125;  // 60 micron sleeves (Sleeve Kings standard)
md_premium = 0.18;  // 90 micron sleeves (Mayday premium)
gg_prime = 0.20;  // 100 micron sleeves (Gamegenic prime)
sk_premium = 0.20;  // 100 micron sleeves (Sleeve Kings premium)
ug_supreme = 0.23;  // 115 micron sleeves (Ultimate Guard supreme)
double_sleeve = 0.30;  // 100 + 50 micron double sleeve

function card_count(h, quality=no_sleeve, card=playing_card) =
    floor(h / (card + quality));
function vdeck(n=1, sleeve, quality, card=playing_card, wide=false) = [
    wide ? max(sleeve.x, sleeve.y) : min(sleeve.x, sleeve.y),
    wide ? min(sleeve.x, sleeve.y) : max(sleeve.x, sleeve.y),
    n*(quality+card)];

// basic metrics
wall0 = xwall(4);
floor0 = qlayer(wall0);
gap0 = 0.1;  // TODO: clean up gap/cut/joint code

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

module tongue(size, h=floor0, h0=undef, h1=undef, h2=undef,
              a=60, groove=false, gap=gap0) {
    // groove = false: positive image. gap is inset from the bounding box.
    // groove = true: negative image. gap is extended above top and below base.
    hroof = !is_undef(h2) ? h2 : h;  // height of column above tongue
    hfloor = !is_undef(h1) ? h1 : h;  // height of tongue
    hbevel = !is_undef(h0) ? h0 : hfloor/2;  // height of bevel
    htop = groove ? hfloor+gap : min(hroof, hfloor+gap);

    slope = tan(a);
    vfloor = groove ? size : size - [gap, gap];
    vbevel = vfloor + [2, 2] * (hfloor-hbevel) / slope;
    vtop = vfloor + [2, 2] * (hfloor-htop) / slope;

    // vtop is higher than vfloor if we're cutting a groove or extending up
    // into a prism. this avoids some messy interactions between the hull and
    // other objects at the same height like floors.
    hull() {
        linear_extrude(htop) stadium_fill(vtop);
        linear_extrude(hbevel) stadium_fill(vbevel);
    }
    if (hroof != htop) linear_extrude(hroof) stadium_fill(vfloor);
    if (groove) linear_extrude(2*gap, center=true) stadium_fill(vbevel);
}

// box metrics
Vfloor = [288, 288];  // box floor
Vinterior = [Vfloor.x, Vfloor.y, 69];  // box interior
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
Dcoin = 3/4*inch;  // trade & resource token diameter
Rhex = 3/4*inch;  // hex major radius (center to vertex)
Rhex1 = 18;  // radius of single hex tiles
Vfocus5 = [371, 21.2, 5*Hboard];
Vfocus4 = [309, 21.6, 4*Hboard];
Vmanual1 = [8.5*inch, 11*inch, 1.6];  // approximate
Vmanual2 = [7.5*inch, 9.5*inch, 1.6];  // approximate

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
    "#202020",
];

// container metrics
Hlid = floor0;  // height of cap lid
Hplug = floor0;  // depth of lid below cap
Hcap = Hlid+Hplug;  // total height of lid + plug

Rsnug = 0*gap0;  // snug joint radius for friction fit
Rlid = 1*gap0;  // lid joint radius (dx from lid/plug to container wall)
// TODO: check on everything affected by Rext change
Rext = 2.5;  // external corner radius
Rint = Rext-wall0;  // internal corner radius (dx from contents to wall)
Rtop = flayer(Rext);  // vertical corner radius
Rxhole = Rhex1*sin(60) - Rint;  // smaller than a single-hex tile

Hseam = gap0;  // space between lid cap and box (display only)
Avee = 60;  // angle for index v-notches and lattices
Dthumb = 25;  // index hole diameter
Gbox = [
    [2.5, 0], [2, 1], [2.5, 2], [2, 3], [2.5, 4], [2, 5],
    [1, 5], [0.5, 4], [-0.5, 4], [-1, 3], [-2, 3],
    [-2.5, 2], [-2, 1], [-2.5, 0], [-2, -1], [-2.5, -2],
    [-2, -3], [-1, -3], [-0.5, -4], [0.5, -4], [1, -3],
    [2, -3], [2.5, -2], [2, -1],
];
Ghole = [
    [1.5, -2], [1.5, 0], [1.5, 2], [1.5, 4],
    [0, -3], [0, -1], [0, 1], [0, 3],
    [-1.5, -2], [-1.5, 0], [-1.5, 2],
];
Gplug = [ [1.5, -4], [1.5, 4], [-1.5, -2], [-1.5, 2], ];

// vertical layout
Hroom = ceil(Vinterior.z - Vmanual1.z - Vmanual2.z) - 1;
function tier_height(k) = k ? flayer(Hroom/k) : Vinterior.z;
function tier_number(z) = floor(Hroom/z);
function tier_ceil(z) = tier_height(tier_number(z));
function tier_room(z) = tier_ceil(z) - z;

// general layout
// designed around box quadrants with some diagonal space across the center
// reserved for focus bar storage.  the focus bars themselves sit to one side,
// but the walls span the midline for stabilitiy.
Rfloor = norm(Vfloor) / 2;  // major radius of box = 203.64mm
Vtray = [135, 85];  // small tray block
// main tier heights: two thick layers + one thinner top layer
Htier = 25;
Htop = 15;

module prism(h, shape=undef, r=undef, r1=undef, r2=undef, scale=1) {
    module curve() {
        ri = !is_undef(r1) ? r1 : !is_undef(r) ? r : 0;  // inside turns
        ro = !is_undef(r2) ? r2 : !is_undef(r) ? r : 0;  // outside turns
        if (ri || ro) offset(r=ro) offset(r=-ro-ri) offset(r=ri) children();
        else children();
    }
    linear_extrude(height=h, scale=scale) curve()
    if (is_undef(shape)) children();
    else if (is_list(shape) && is_list(shape[0])) polygon(shape);
    else square(shape, center=true);
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

// focus bar components & containers
module focus_bar(v, color=5) {
    k = floor(v.x / 60);
    module focus(n, cut=false) {
        origin = [-60 * (k+1)/2, 0];
        translate(origin + [60 * n, 0]) if (cut) {
            cube([50, 12, 2*v.z], center=true);
        } else {
            difference() {
                color("tan", 0.60) cube([50, 12, v.z], center=true);
                cube([48, 10, 2*v.z], center=true);
            }
            color("olivedrab", 0.60) cube([48, 10, v.z], center=true);
        }
    }
    raise(v.z/2) {
        difference() {
            color("tan", 0.60) cube(v, center=true);
            cube([k*60, 16, 2*v.z], center=true);
        }
        c = is_num(color) ? player_colors[color] : color;
        color(c, 0.60) difference() {
            cube([k*60, 16, v.z], center=true);
            for (n=[1:k]) focus(n, cut=true);
        }
        for (n=[1:k]) focus(n);
    }
}

// TODO: switch to a flat 15mm tray
Vfframe0 = [  // minimum size
    norm([Vinterior.x, Vinterior.y]),  // diagonal length
    2*max(Vfocus4.y, Vfocus5.y) + 3*wall0 + 2*Rint,
    max(Vfocus4.z, Vfocus5.z) + floor0 + Rint,
];
Vfframe = vround([Vfframe0.x, Vfframe0.y, Htop]);
assert(vfit(Vfframe, Vfframe0, "FOCUS BAR FRAME"));
module focus_frame(section=undef, xspread=0, gap=gap0, color=undef) {
    // section:
    // undef = whole part
    // -1 = left only
    //  0 = joiner only
    // +1 = right only

    // well sizes
    ywell = (Vfframe.y - 3*wall0) / 2;
    f5well = [Vfocus5.x+2*Rint, ywell];
    f4well = [Vfocus4.x+2*Rint, ywell];
    y0 = -f5well.y/2-wall0;
    // space between sections
    xjoint = 40;
    xspan = xspread + xjoint;
    vtray = [Vfframe.x + xspread, Vfframe.y, Vfframe.z];

    module joiner_tongue(groove=false) {
        d = vtray.y/2;
        top = [xspan + 2*d, d];
        translate([0, y0+vtray.y/2]) tongue(top, groove=groove, h2=vtray.z);
    }
    module joiner() {
        intersection() {
            tray();
            union() {
                joiner_tongue();
                translate([0, y0+vtray.y/2])
                    prism(vtray.z, [xspan-gap, vtray.y]);
            }
        }
    }
    module half(side) {
        difference() {
            intersection() {  // confine to one half
                tray();
                scale([side, 1]) translate([xspan/2, y0]) cube(vtray);
            }
            if (section) joiner_tongue(groove=true);  // subtract joiner
        }
    }
    module tray() {
        y1 = 0;
        y2 = y0 + vtray.y;
        x1 = vtray.x/2;
        x2 = x1+y0;
        x3 = x1-y2;
        x4 = x3-2*Rext;
        corner = [[x1, y1], [x3, y2], [x4, y2], [x4, y0], [x2, y0]];
        color(color) difference() {
            // shell
            linear_extrude(vtray.z) hull() for (i=[-1,+1]) scale([i, 1])
                offset(r=Rext) offset(r=-Rext) polygon(corner);
            // focus bar wells
            raise() {
                prism(vtray.z, f5well, r=Rint);
                translate([0, y2-wall0-f4well.y/2])
                    prism(vtray.z, f4well, r=Rint);
            }
            translate([0, y0+vtray.y/2]) {
                raise() for (i=[-1,+1]) translate([0, i/2*(vtray.y-wall0)])
                    wall_vee_cut([xspan, 2*wall0, vtray.z-floor0]);
                // thumb rounds
                for (i=[-1,+1])
                    translate([0, i*(vtray.y/2+Dthumb/3), -gap0])
                    prism(floor0+2*gap) circle(d=Dthumb);
            }
        }
    }
    if (section) {
        // one end half only
        half(sign(section));
    } else if (section == 0) {
        // joiner only
        joiner();
    } else {
        tray();  // whole tray
        %raise() {  // ghost focus bars
            focus_bar(Vfocus5);
            translate([0, y0+vtray.y-wall0-f4well.y/2])
                focus_bar(Vfocus4, color=2);
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
module hex_lid(grid=Ghex, r=Rhex, color=undef) {
    assert(Hcap == Hlid+Hplug);
    color(color) {
        // lid
        prism(Hlid, r1=Rint, r2=Rext)
            offset(delta=Rext) hex_poly(grid=grid, r=r);
        // plug
        raise(-Hplug) prism(Hcap, r1=Rext, r2=Rint)
            offset(delta=Rint-Rlid) hex_poly(grid=grid, r=r);
    }
}

function hex_box_height(n=1) = clayer(floor0 + n*Hboard + Rtop);
function hex_box_min_height(n=1) = qlayer(floor0 + n*Hboard + Rint);
function sum(v) = v ? [for(p=v) 1]*v : 0;
function stack_height(v=[], plug=false, lid=false) =
    sum([for (n=v) hex_box_height(n)]) +  // box heights
    max(0, len(v)-1)*clayer(Hseam) +  // gaps between boxes
    (plug ? Hplug : 0) +  // plug below
    (lid ? sign(len(v))*clayer(Hseam) + Hlid : 0);  // lid above

module hex_box(n=1, h=undef, grid=Ghex, r=Rhex, ghost=undef, color=undef) {
    height = h ? h : hex_box_height(n);
    hmin = hex_box_min_height(n);
    assert(hmin <= height);
    echo(height=height, rec=hex_box_height(n), min=hex_box_min_height(n));
    color(color) difference() {
        // exterior
        prism(height, r1=Rint, r2=Rext)
            offset(delta=Rext) hex_poly(grid=grid, r=r);
        // interior
        raise() prism(height, r1=Rext, r2=Rint)
            offset(delta=Rint) hex_poly(grid=grid, r=r);
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
module map_tile_hole(gap=gap0) {
    raise(-Hplug-gap) prism(Hcap+2*gap, r=Rext) hex_poly(r=Rxhole);
}
module map_tile_box(n=Nmaps, h=undef, color=undef) {
    difference() {
        hex_box(n=n, h=h, grid=Gbox, ghost=Gmap, color=color);
        for (p=hex_points(Ghole)) translate(p)
            map_tile_hole();
    }
}
module map_tile_capitals(color=undef) {
    // the 5 capital city tiles + the 5 forts
    map_tile_box(n=Nplayers, color=color);
}
module map_tile_core_stack(color=undef) {
    // the 16 map tiles for core + map stack
    map_tile_box(n=Nmaps, h=40, color=color);
}
module map_tile_lid(color=undef) {
    color(color) difference() {
        hex_lid(grid=Gbox);
        for (p=hex_points(Ghole)) translate(p) map_tile_hole();
    }
}
module map_tile_plug(gap=gap0, color=undef) {
    assert(Hcap == Hlid+Hplug);
    color(color) difference() {
        union() {
            // insert
            prism(Hlid, r=Rext) offset(delta=-Rsnug) hex_poly(r=Rxhole);
            // plug
            raise(-Hplug) prism(Hplug, r1=Rext, r2=Rint)
                offset(delta=Rint-Rlid) hex_poly();
        }
        // new index hole inset by 1 wall thickness
        raise(-Hplug-gap) prism(Hcap+2*gap, r=Rint)
            offset(delta=-Rsnug-wall0) hex_poly(r=Rxhole);
    }
}
module map_hex_box(n=Nplayers, h=undef, color=undef) {
    difference() {
        hex_box(n=n, h=h, grid=Ghex, color=color);
        map_tile_hole();
    }
}
module map_hex_lid(color=undef) {
    color(color) difference() {
        hex_lid(grid=Ghex);
        map_tile_hole();
    }
}
module raise_lid(v=[], plug=false) {
    raise(stack_height(v, plug=plug, lid=true) - Hlid) children();
}
module map_tile_tower(lift=Hseam, color=undef) {
    // TODO: plugs and stuff
    map_tile_core_stack(color=color);
    raise_lid([Nmaps]) {
        map_tile_capitals(color=color);
        raise_lid([Nplayers]) map_tile_lid(color=color);
    }
}

function deck_box_volume(v) = vround([
    v.y + 2*Rext,
    v.z + 2*wall0,  // TODO: might be too snug for the universal deck
    v.x + Rtop + floor0]);
function card_tray_volume(v) = vround([
    v.x + 2*Rext,
    v.y + 2*Rext,
    v.z + Rtop + floor0]);

// player focus decks: Gamegenic green sleeves
Vdeck = vdeck(29, green_sleeve, gg_prime);
Vdbox0 = deck_box_volume(Vdeck);
Vdbox = vround([Vdbox0.x, 20, Vdbox0.z]);
assert(vfit(Vdbox, Vdbox, "DECK BOX"));
module deck_box(v=Vdeck, color=undef) {
    vbox = deck_box_volume(v);
    well = vbox - 2*[wall0, wall0];
    // notch dimensions:
    hvee = qlayer(vbox.z/2);  // half the height of the box
    dvee = 2*hvee/tan(Avee);  // point of the vee exactly at the base
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

module card_well(deck, tray=undef, a=Avee, gap=gap0) {
    // TODO: improve conversions between deck, well, and shell sizes
    vtray = tray ? tray : card_tray_volume(deck);
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

module card_tray(deck, tray=undef, color=undef) {
    vtray = tray ? tray : card_tray_volume(deck);
    shell = [vtray.x, vtray.y];
    well = shell - [2*wall0, 2*wall0];
    color(color) difference() {
        linear_extrude(vtray.z) rounded_square(Rext, shell);
        card_well(deck, vtray);
    }
    // card stack
    %raise(floor0 + deck.z/2) cube(deck, center=true);
}

// leader sheets: thick card with Sleeve Kings super large sleeve
Vleaders = vdeck(18, super_large_sleeve, sk_standard, leader_card, wide=true);
Vltray0 = card_tray_volume(Vleaders);
Vltray = [Vtray.x, 110, 15];
assert(vfit(Vltray, Vltray0, "LEADERS TRAY"));
module leaders_tray(color=undef) {
    // TODO: expand this to exactly 135x110mm?
    card_tray(Vleaders, Vltray, color=color);
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

Vwdeck = vdeck(9, yellow_sleeve, gg_prime, wide=true);
Vwtray0 = [
    max(Vwdeck.x, 3*Vwonder.x + 2*Rint) + 2*Rext,
    Vwdeck.y + Rint + Vwonder.y + 3*Rext,
    max(Vwdeck.z, 3*Vwonder.z) + Rext + floor0,
];
Vwtray = vround([72.5, Vtray.y, flayer(Htier/2)]);
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
        vtray.z - Rext - floor0,
    ];
    wtiles = [vtiles.x, vtiles.y, vtray.z - Rext - floor0];
    xtile = (vtray.x-wall0)/3 - vtiles.x;  // wonder tile x-spacing
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

Dcbanner = 12;  // width of the title banner on city-state cards
Vcdeck = vdeck(4, yellow_sleeve, gg_prime);
Vctray0 = [  // minimum size to stagger two cards with both titles visible
    Vcdeck.x + Dcbanner + 2*Rext,
    Vcdeck.y + Dcbanner + 2*Rext,
    Vcdeck.z + max(Hboard + Rint, Rext) + floor0,
];
Vctray = vround([62, Vtray.y, flayer(Htier/3)]);
assert(vfit(Vctray, Vctray0, "CITY-STATES TRAY"));
module city_states_tray(color=undef) {
    vtray = Vctray;
    vcards = Vcdeck;
    pcorner = [vtray.x/2-wall0, vtray.y/2-wall0];
    pindent = [pcorner.x - vcards.x - 2*Rint, vcards.y + 2*Rint - pcorner.y];
    vwell = [
        [pcorner.x, pcorner.y],
        [pindent.x, pcorner.y],
        [pindent.x, pindent.y],
        [-pcorner.x, pindent.y],
        [-pcorner.x, -pcorner.y],
        [-pindent.x, -pcorner.y],
        [-pindent.x, -pindent.y],
        [pcorner.x, -pindent.y],
    ];
    ucards = [vcards.x, vcards.y];
    wcards = ucards + 2*[Rint, Rint];
    pcards = vtray/2 - wcards/2 - [wall0, wall0];
    ahex = 90;
    rhex = Rhex1 * sin(60);  // minor radius
    uhex = Rhex1 * [cos(abs(ahex % 60)), cos(abs(ahex % 60) - 30)];
    phex = [vtray.x/2-Rext-uhex.x, vtray.y/2-Rext-uhex.y];
    color(color) difference() {
        prism(vtray.z, [vtray.x, vtray.y], r=Rext);
        raise() prism(vtray.z, vwell, r=Rint);
        // use a bottom index hole only, smaller than the hex tile
        linear_extrude(3*floor0, center=true) circle(floor(rhex));
    }
    %raise() {
        for (i=[-1,+1]) raise(vcards.z * (1+i/2)/2)
            translate(i*pcards) prism(vcards.z/2, ucards);
        raise(vcards.z) translate(phex) rotate(ahex) hex_tile(r=Rhex1);
    }
}

module tier_info(name, v) {
    h = v.z;
    echo(name);
    echo(v=v, inches=[for (i=v/inch) eround(i)]);
    echo(h=h, n=tier_number(h), c=tier_ceil(h), r=tier_room(h));
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
    // focus bars
    raise(2*Htier) rotate(135) focus_frame(color=player_colors[0]);
    // player deck boxes
    deltadb = [Vdbox.x+gap0, Vdbox.y+gap0];
    translate([Vdbox.x/2-Vfloor.x/2, Vdbox.y/2-Vfloor.y/2])
        for (player=[0:6]) translate([0, player*deltadb.y, 0])
            deck_box(color=player_colors[6-player]);
    // map tiles
    // TODO: move stuff around
    xstack = 10*Rhex*sin(60) + 2*Rext;
    ystack = 5*Rhex + 2*Rext;
    translate([Vfloor.x/2-xstack/2+Rhex*sin(60), Vfloor.y/2-ystack/2])
        rotate(90) map_tile_tower(color=player_colors[0]);
    // everything above the bar
    // TODO: distribute about 1mm space around this area
    translate([Vfloor.x/2-Vtray.x/2, -Vfloor.y/2]) {
        // wonder trays
        for (j=[0:3])
            translate([(Vwtray.x-Vtray.x)/2, Vwtray.y/2, j*(Vwtray.z+gap0)])
                wonders_tray();
        // city states
        for (j=[0:5])
            translate([(Vtray.x-Vctray.x)/2, Vctray.y/2, j*(Vctray.z+gap0)])
            city_states_tray();
        // leader tray
        translate([0, -Vltray.y/2])
        leaders_tray(color=player_colors[0]);
    }
    // TODO: event dials
    // TODO: barbarian tokens
    // TODO: natural wonders & resource tokens
    // TODO: trade tokens
    // TODO: player trays
}

// tests for card trays
module test_trays() {
    vgreen1 = vdeck(18, green_sleeve, gg_prime, wide=false);
    vgreen2 = vdeck(18, green_sleeve, gg_prime, wide=true);
    vyellow1 = vdeck(18, yellow_sleeve, gg_prime, wide=false);
    vyellow2 = vdeck(18, yellow_sleeve, gg_prime, wide=true);
    card_tray(Vleaders);
    translate([90+vgreen1.x/2, 0]) card_tray(vgreen1);
    translate([0, 75+vgreen2.y/2]) card_tray(vgreen2);
    translate([-90-vyellow1.x/2, 0]) card_tray(vyellow1);
    translate([0, -75-vyellow2.y/2]) card_tray(vyellow2);
    translate([0, -95-vyellow2.y]) {
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
*map_tile_plug();
*map_hex_box();
*map_hex_lid();
*deck_box();
*leaders_tray();
*wonders_tray();
*city_states_tray();

*map_hex_box(h=15);
*map_tile_tower(lift=3);
test_trays();
*organizer();
