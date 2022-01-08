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

tolerance = 0.001;

$fa = 15;
$fs = min(layer_height/2, xspace(1)/2);

inch = 25.4;
card = [2.5*inch, 3.5*inch];  // standard playing card dimensions

// seams add about 1/2mm to each dimension
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

no_sleeve = 0.35;  // common unsleeved card thickness (UG assumes 0.325)
thin_sleeve = 0.1;  // 50 micron sleeves
thick_sleeve = 0.2;  // 100 micron sleeves
double_sleeve = thick_sleeve + thin_sleeve;
function double_sleeve_count(d) = floor(d / (no_sleeve + double_sleeve));
function thick_sleeve_count(d) = floor(d / (no_sleeve + thick_sleeve));
function thin_sleeve_count(d) = floor(d / (no_sleeve + thin_sleeve));
function unsleeved_count(d) = floor(d / no_sleeve);
function vdeck(n=1, card=yellow_sleeve, sleeve=double_sleeve) =
    [card[0], card[1], n*(no_sleeve+sleeve)];

function unit_axis(n) = [for (i=[0:1:2]) i==n ? 1 : 0];

wall0 = xwall(4);
floor0 = qlayer(wall0);
gap0 = 0.1;

// box metrics
interior = [287, 287, 67.5];  // box interior
module box(size, wall=1, frame=false, a=0, center=false) {
    vint = is_list(size) ? size : [size, size, size];
    vext = [vint[0] + 2*wall, vint[1] + 2*wall, vint[2] + wall];
    vcut = [vint[0], vint[1], vint[2] - wall];
    origin = center ? [0, 0, vext[2]/2 - wall] : vext/2;
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
    }
}

// component metrics
Nplayers = 5;
Nmaps = 16;  // number of map and water tiles
Hboard = 2.25;  // tile & token thickness
Rhex = 3/4 * 25.4;  // hex major radius (center to vertex)
Hcap = clayer(4);  // total height of lid + plug
Vfocus5 = [371, 11.5, 21.5];
Vfocus4 = [309, 9, 22];
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

// container metrics
Hlid = floor0;  // height of cap lid
Hplug = Hcap - Hlid;  // depth of lid below cap
Rint = 1;  // internal corner radius (distance from contents to wall)
Rext = Rint+wall0;  // external corner radius
Rplug = Rint-gap0;  // internal plug radius (small gap to wall interior)
Alid = 30;  // angle of lid chamfer
Hseam = wall0/2 * tan(Alid) - zlayer(1/2);  // space between lid cap and box
Hchamfer = (Rext-Rplug) * tan(Alid);
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
function diag2(x, y) = sqrt(x*x + y*y);
function diag3(x, y, z) = sqrt(x*x + y*y + z*z);

module interior(a=45, center=false) {
    origin = [0, 0, center ? 0 : interior[2]/2];
    translate(origin) rotate(a) cube(interior, center=true);
}

module focus_frame(half=0, center=false) {
    axis = sign(half);
    // TODO: switch to full Rext border instead of 1/2 Rint + wall0?
    slot5 = [Vfocus5[0]+Rint, Vfocus5[1]+Rint, clayer(Vfocus5[2]+0.8)];
    slot4 = [Vfocus4[0]+Rint, Vfocus4[1]+Rint, clayer(Vfocus4[2])+slot5[2]];
    block = [
        diag2(interior[0], interior[1]),
        max(slot4[1], slot5[1]) + 2*wall0,
        slot4[2] + floor0,
    ];

    origin = [0, 0, center ? 0 : block[2]/2];
    module cut(slot, block) {
        cut = [slot[0], slot[1], 2*slot[2]];
        translate([0, 0, block[2]/2]) cube(cut, center=true);
    }
    module vee(slot, block) {
        vee = [
            [0, floor0 - block[2]],
            [+slot[0]/2, 0],
            [+slot[0]/2, 1],
            [-slot[0]/2, 1],
            [-slot[0]/2, 0],
        ];
        translate([0, 0, block[2]/2]) rotate([90, 0, 0])
            linear_extrude(2*block[1], center=true) polygon(vee);
    }
    module half(slot, block) {
        if (axis != 0) rotate(90*sign(axis)) {
            notch = slot[1]/2;
            jig = [
                [-notch+gap0/2, 0],
                [-notch+gap0/2, +2*notch],
                [-gap0/2, +2*notch],
                [-gap0/2, -2*notch],
                [notch, -2*notch],
                [notch, 0],
                [+block[1], 0],
                [+block[1], +block[0]],
                [-block[1], +block[0]],
                [-block[1], 0],
            ];
            linear_extrude(2*block[2], center=true) polygon(jig);
        }
    }
    translate(origin) intersection() {
        interior(center=true);
        translate([0, block[1]/2, 0])
        difference() {
            cube(block, center=true);
            cut(slot5, block);
            cut(slot4, block);
            vee(slot5, block);
            half(slot4, block);
        }
    }
}

module raise(z=floor0) {
    translate([0, 0, z]) children();
}
module rounded_square(r, size, center=true) {
    offset(r=r) offset(r=-r) square(size, center);
}

function hex_grid(x, y, r=Rhex) = [r*x, sin(60)*r*y];
function hex_points(grid=Ghex, r=Rhex) = [for (i=grid) hex_grid(i[0],i[1],r)];
function hex_min(grid=Ghex, r=Rhex) =
    hex_grid(min([for (i=grid) i[0]]), min([for (i=grid) i[1]]), r);

module hex_poly(grid=Ghex, r=Rhex, center=false) {
    origin = center ? [0, 0] : -hex_min(grid, r);
    translate(origin) polygon(hex_points(grid, r));
}
module hex_tile(n=1, grid=Ghex, r=Rhex, center=false) {
    linear_extrude(Hboard*n, center=center)
        hex_poly(grid=grid, r=r, center=center);
}
module hex_lid(grid=Ghex, r=Rhex, center=false) {
    xy_min = hex_min(grid, r);
    origin = center ? [0, 0, 0] : [Rext - xy_min[0], Rext - xy_min[1], 0];
    translate(origin) {
        minkowski() {
            linear_extrude(Hlid, center=false)
                hex_poly(grid=grid, r=r, center=true);
            mirror([0, 0, 1]) {
                cylinder(h=Hplug, r=Rplug);
                cylinder(h=Hchamfer, r1=Rext, r2=Rplug);
            }
        }
    }
}

function hex_box_height(n=1, plug=false) =
    clayer(floor0 + n*Hboard + Rint + Hplug) + (plug ? Hplug : 0);
function stack_height(n=0, k=1, plug=true, lid=true) =
    (k ? hex_box_height(n) : 0) +
    (k-1)*clayer(Hseam) +
    (plug ? Hplug : 0) +
    (lid ? clayer(Hseam) + Hlid : 0);

module hex_box(n=1, plug=false, grid=Ghex, r=Rhex, ghost=undef, center=false) {
    h = hex_box_height(n=n, plug=false);
    origin = center ? [0, 0] : -hex_min(grid, r) + [1, 1] * Rext;
    translate(origin) {
        difference() {
            // exterior
            union() {
                linear_extrude(h, center=false)
                    offset(r=Rext) hex_poly(grid=grid, r=r, center=true);
                if (plug) hex_lid(grid=grid, r=r, center=true);
            }
            // interior
            raise() linear_extrude(h, center=false)
                offset(r=Rext-wall0) hex_poly(grid=grid, r=r, center=true);
            // lid chamfer
            raise(h+Hseam) hex_lid(grid=grid, center=true);
        }
        // ghost tiles
        %raise(floor0 + Hboard * n/2)
            hex_tile(n=n, grid=(ghost ? ghost : grid), r=r, center=true);
    }
}

module map_hex_poly(center=false) {
    hex_poly(grid=Ghex, center=center);
}
module map_hex(n=1, center=false) {
    hex_tile(n=n, grid=Ghex, center=center);
}
module map_tile_poly(center=false) {
    hex_poly(grid=Gmap, center=center);
}
module map_tile(n=1, center=false) {
    hex_tile(n=n, grid=Gmap, center=center);
}
module map_tile_box(n=Nmaps, plug=false, center=false) {
    difference() {
        hex_box(n=n, plug=plug, grid=Gbox, ghost=Gmap, center=center);
        for (p=hex_points(Ghole)) translate(p)
            linear_extrude(2*Hcap, center=true)
            offset(r=Rext) offset(r=-Rhex/4-Rext) hex_poly(center=center);
    }
}
module map_tile_capitals(center=false) {
    map_tile_box(n=Nplayers, plug=true, center=center);
}
module map_tile_lid(center=false) {
    difference() {
        hex_lid(grid=Gbox, center=center);
        for (p=hex_points(Ghole)) translate(p)
            linear_extrude(2*Hcap, center=true)
            offset(r=Rint) offset(delta=-Rhex/4-Rint) hex_poly(center=center);
    }
}
module raise_lid(n=0, k=1, plug=false) {
    raise(stack_height(n=n, k=k, plug=plug, lid=true) - Hlid) children();
}
module map_tile_stack() {
    nmap = 16;
    ncap = 5;
    map_tile_box(nmap, center=true);
    raise_lid(nmap) {
        map_tile_box(ncap, plug=true, center=true);
        raise_lid(ncap) map_tile_lid(center=true);
    }
}

Vdeck = vdeck(29, green_sleeve, thick_sleeve);
Vdbox = [  // round dimensions to even layers
    qlayer(Vdeck[1] + 2*Rext),
    qlayer(Vdeck[2] + 2*Rext),
    qlayer(Vdeck[0] + Rint + floor0),
];

module deck_box(color=undef, center=false) {
    origin = center ? [0, 0, 0] : Vdbox/2;
    module shell(block) {
        raise((-block[2])/2) linear_extrude(block[2]/2)
            rounded_square(Rext, [block[0], block[1]]);
        for (a=[0,180]) rotate(a) {
            translate([block[0]/2-2*Rext, 0])
                linear_extrude(block[2], center=true)
                rounded_square(Rext, [4*Rext, block[1]]);
            vee = [
                [0, 0],
                [block[0]/2-Rext, 0],
                [block[0]/2-Rext, block[2]],
                [block[0]/3-Rext, block[2]],
            ];
            raise(-block[2]/2) rotate([90, 0, 0])
                linear_extrude(block[1], center=true)
                offset(r=Rext) offset(r=-Rext)
                polygon(vee);
        }
    }
    translate(origin) {
        well = [Vdbox[0]-2*wall0, Vdbox[1]-2*wall0];
        color(color) difference() {
            shell(Vdbox);
            raise() linear_extrude(Vdbox[2], center=true)
                rounded_square(Rint, [well[0], well[1]]);
        }
        %raise() raise(Vdeck[0]/2-Vdbox[2]/2)
            rotate([0, 90, 90]) cube(Vdeck, center=true);
    }
}

module organizer() {
    // box shape and manuals
    // everything needs to fit inside this!
    %color("#101080", 0.5) box(interior, frame=true, center=true);
    %color("#101080", 0.1) raise(interior[2] - Vmanual2[2]/2) {
        cube(Vmanual2, center=true);
        raise(-(Vmanual1[2]+Vmanual2[2])/2) cube(Vmanual1, center=true);
    }
    rotate(135) {
        // focus bars
        focus_frame();
        translate([0, Vfocus5[1]+Rext+wall0+gap0]) {
            deltadb = [Vdbox[0]+gap0, Vdbox[1]+gap0];
            // player deck boxes
            dc = ["darkorange", "springgreen", "aqua",
                "crimson", "maroon", "mediumpurple"];
            for (x=[-1, 0, +1]) for (y=[1, 2])
                translate([x*deltadb[0], (y-0.5)*deltadb[1], Vdbox[2]/2])
                    deck_box(color=dc[3*y+x-2], center=true);
            // map tiles
            ystack = 5*Rhex + 2*Rext + gap0;
            translate([0, 2*deltadb[1]+ystack/2]) rotate(-90) map_tile_stack();
        }
    }
}

*map_tile_box(center=true);
*map_tile_capitals(center=true);
*map_tile_lid(center=true);
*deck_box(center=true);

organizer();
