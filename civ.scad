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
function diag2(x, y) = sqrt(x*x + y*y);
function diag3(x, y, z) = sqrt(x*x + y*y + z*z);

module raise(z=floor0) {
    translate([0, 0, z]) children();
}
module rounded_square(r, size) {
    offset(r=r) offset(r=-r) square(size, center=true);
}

wall0 = xwall(4);
floor0 = qlayer(wall0);
gap0 = 0.1;

// box metrics
Vinterior = [287, 287, 67.5];  // box interior
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
    }
}

// component metrics
Nplayers = 5;
Nmaps = 16;  // number of map and water tiles
Hboard = 2.25;  // tile & token thickness
Rhex = 3/4 * 25.4;  // hex major radius (center to vertex)
Hcap = clayer(4);  // total height of lid + plug
Vfocus5 = [371, 5*Hboard, 21.5];
Vfocus4 = [309, 4*Hboard, 22];
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

Vfframe = [for (x=[  // round dimensions to even layers
    diag2(Vinterior[0], Vinterior[1]),
    max(Vfocus4[1], Vfocus5[1]) + 2*Rext - Rint,  // 1mm narrower than usual
    floor0 + Vfocus4[2] + Vfocus5[2] + 2*Rint,
]) qlayer(x)];

module wall_vee(size, span, a=64.5, side=undef) {
    y0 = 0;
    y1 = floor0;
    y2 = size[2];
    rise = y2 - y1;
    run = rise/tan(a);
    x0 = span/2;
    x1 = x0 + run;
    x2 = x1 + 2*Rext;
    x3 = size[0]/2;
    poly = [[x2, y0], [x2, y2], [x1, y2], [x0, y1], [x0, y0]];
    draw = side ? [sign(side)] : [-1, +1];
    for (s=draw) scale([s, 1, 1]) translate([0, size[1]/2]) rotate([90, 0, 0])
            linear_extrude(size[1]) hull() {
        offset(r=Rext) offset(r=-Rext) polygon(poly);
        translate([x0, 0]) square([x3-x0, y1]);
        translate([x3-gap0, 0]) square([gap0, y2]);
    }
}

module focus_frame(section=undef, color=undef) {
    // section:
    // undef = whole part
    // -1 = left only
    //  0 = joiner only
    // +1 = right only

    // wall thicknesses
    f5wall = wall0;
    f4wall = qwall((Vfocus5[1] - Vfocus4[1]) / 2 + wall0);
    // well sizes (1mm longer than usual)
    f5well = [Vfocus5[0] + 3*Rint, Vfframe[1] - 2*f5wall];
    f4well = [Vfocus4[0] + 3*Rint, Vfframe[1] - 2*f4wall];
    // space between sections
    xjoint = 1.5*inch;

    module shell(block, side) {
        color(color) {
            y0 = 0;
            y1 = Vfframe[1];
            x0 = Vfframe[0]/2 + Rext;
            x1 = x0 - Vfframe[1];
            x2 = x1 - 2*Rext;
            x3 = Vfocus4[0]/2;
            corner = [[x0, y0], [x1, y1], [x2, y1], [x2, y0]];
            linear_extrude(Vfframe[2]) hull() {
                offset(r=Rext) offset(r=-Rext) polygon(corner);
                translate([x3, 0]) square(y1);
            }
            translate([0, Vfframe[1]/2])
                wall_vee([f4well[0], Vfframe[1], Vfframe[2]], xjoint, side=+1);
        }
    }
    if (section) {  // half riser only
        side = sign(section);
        // color(color)
        scale([sign(section), 1]) difference() {
            shell(Vfframe, side);
            translate([0, Vfframe[1]/2]) raise() {
                linear_extrude(Vfframe[2]) rounded_square(Rint, f4well);
                raise(Vfocus4[2]+Rint)
                    linear_extrude(Vfframe[2]) rounded_square(Rint, f5well);
            }
            // joint notch
            translate([0, Vfframe[1]/2]) linear_extrude(3*floor0, center=true)
                square([xjoint*3, f4well[1]-2*gap0], center=true);
        }
    } else if (section == 0) {  // joiner only
        color(color) {
            translate([0, Vfframe[1]/2]) linear_extrude(floor0) {
                square([xjoint, Vfframe[1]], center=true);
                square([xjoint*3, f4well[1]-2*gap0], center=true);
            }
        }
    } else {
        focus_frame(+1, color=color);
        focus_frame(-1, color=color);
        color(color) {
            translate([0, Vfframe[1]/2]) linear_extrude(floor0) {
                square([xjoint*3, Vfframe[1]], center=true);
            }
        }
        // ghost focus bars
        %translate([0, Vfframe[1]/2]) {
            raise(floor0 + Vfocus4[2]/2) cube(Vfocus4, center=true);
            raise(floor0 + Vfocus4[2] + Rint + Vfocus5[2]/2)
                cube(Vfocus5, center=true);
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
function stack_height(n=0, k=1, plug=true, lid=true) =
    (k ? hex_box_height(n) : 0) +
    (k-1)*clayer(Hseam) +
    (plug ? Hplug : 0) +
    (lid ? clayer(Hseam) + Hlid : 0);

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
module raise_lid(n=0, k=1, plug=false) {
    raise(stack_height(n=n, k=k, plug=plug, lid=true) - Hlid) children();
}
module map_tile_stack(color=undef) {
    nmap = 16;
    ncap = 5;
    map_tile_box(nmap, color=color);
    raise_lid(nmap) {
        map_tile_box(ncap, plug=true, color=color);
        raise_lid(ncap) map_tile_lid(color=color);
    }
}

Vdeck = vdeck(29, green_sleeve, thick_sleeve);
Vdbox = [for (x=[  // round dimensions to even layers
    Vdeck[1] + 2*Rext,
    Vdeck[2] + 2*Rext,
    Vdeck[0] + Rint + floor0,
]) qlayer(x)];

module deck_box(color=undef) {
    module shell(block) {
        linear_extrude(block[2]/2)
            rounded_square(Rext, [block[0], block[1]]);
        for (a=[0,180]) rotate(a) {
            translate([block[0]/2-2*Rext, 0])
                linear_extrude(block[2])
                rounded_square(Rext, [4*Rext, block[1]]);
            vee = [
                [0, 0],
                [block[0]/2-Rext, 0],
                [block[0]/2-Rext, block[2]],
                [block[0]/3-Rext, block[2]],
            ];
            rotate([90, 0, 0])
                linear_extrude(block[1], center=true)
                offset(r=Rext) offset(r=-Rext)
                polygon(vee);
        }
    }
    well = [Vdbox[0]-2*wall0, Vdbox[1]-2*wall0];
    color(color) difference() {
        shell(Vdbox);
        raise() linear_extrude(Vdbox[2])
            rounded_square(Rint, [well[0], well[1]]);
    }
    %raise(floor0 + Vdeck[0]/2) rotate([0, 90, 90]) cube(Vdeck, center=true);
}

module organizer() {
    // box shape and manuals
    // everything needs to fit inside this!
    %color("#101080", 0.5) box(Vinterior, frame=true);
    %color("#101080", 0.1) translate([-Vinterior[0]/2, -Vinterior[1]/2]) {
        raise(Vinterior[2]-Vmanual1[2]-Vmanual2[2]) {
            cube(Vmanual1);
            raise(Vmanual2[2]) cube(Vmanual2);
        }
    }
    // focus frame bar and everything below
    rotate(135) translate([0, -Rext]) {
        // focus bars
        focus_frame(color="maroon");
        translate([0, Vfframe[1]+gap0]) {
            // player deck boxes
            deltadb = [Vdbox[0]+gap0, Vdbox[1]+gap0];
            dc = ["darkorange", "springgreen", "aqua",
                "crimson", "maroon", "mediumpurple"];
            translate([0, Vdbox[1]/2])
                for (x=[-1, 0, +1]) for (y=[0, 1])
                translate([x*deltadb[0], y*deltadb[1], 0])
                    deck_box(color=dc[3*y+x+1]);
            // map tiles
            ystack = 5*Rhex + 2*Rext;
            translate([0, 2*deltadb[1]+ystack/2]) rotate(-90)
                map_tile_stack(color="maroon");
        }
    }
    // everything above the bar
    rotate(-45) translate([0, Rext+gap0]) {
        // TODO
    }
}

*focus_frame(+1);
*focus_frame(-1);
*focus_frame(0);
*raise(-floor0-gap0) focus_frame(0);
*map_tile_box();
*map_tile_capitals();
*map_tile_lid();
*deck_box();

organizer();
