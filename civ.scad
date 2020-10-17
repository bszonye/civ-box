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

// quantize heights
function zlayer(n=1) = n*layer_height;
function nlayer(z=zlayer()) = z/layer_height;
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
function vdeck(n=1, sleeve=double_sleeve, card=yellow_sleeve) =
    [card[0], card[1], n*(no_sleeve+sleeve)];

function unit_axis(n) = [for (i=[0:1:2]) i==n ? 1 : 0];

wall0 = xwall(4);
floor0 = qlayer(wall0);
gap0 = 0.1;

interior = [287, 287, 67.5];

function diag2(x, y) = sqrt(x*x + y*y);
function diag3(x, y, z) = sqrt(x*x + y*y + z*z);

module interior(a=45, center=false) {
    origin = [0, 0, center ? 0 : interior[2]/2];
    translate(origin) rotate(a) cube(interior, center=true);
}

module focus_frame(half=0, center=false) {
    axis = sign(half);
    focus6 = [371, 11.5, 21.5];
    focus5 = [309, 9, 22];
    slot6 = [focus6[0] + 1, focus6[1] + 1, clayer(focus6[2] + 0.8)];
    slot5 = [focus5[0] + 1, focus5[1] + 1, clayer(focus5[2]) + slot6[2]];
    block = [
        diag2(interior[0], interior[1]),
        max(slot5[1], slot6[1]) + 2*wall0,
        slot5[2] + floor0,
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
            cut(slot6, block);
            cut(slot5, block);
            vee(slot6, block);
            half(slot5, block);
        }
    }
}

module raise(z=floor0) {
    translate([0, 0, z]) children();
}

module deck_box(center=false) {
    cards = [green_sleeve[0]+0.5, green_sleeve[1]+0.5, 16];
    block = [
        ceil(cards[1]+1+2*wall0),
        ceil(cards[2]+1+2*wall0),
        ceil(cards[0]+1+floor0),
    ];
    origin = center ? [0, 0, 0] : block/2;
    module vee(depth, block) {
        x = block[0]/2 - wall0;
        vee = [
            [-x*2/3, 0],
            [-x/3, depth+floor0-block[2]],
            [+x/3, depth+floor0-block[2]],
            [+x*2/3, 0],
            [+x, 0],
            [+x, 1],
            [-x, 1],
            [-x, 0],
        ];
        translate([0, 0, block[2]/2]) rotate([90, 0, 0])
            linear_extrude(2*block[1], center=true) polygon(vee);
    }
    module shell(block) {
        well = block - [2*wall0, 2*wall0, 0];
        difference() {
            cube(block, center=true);
            raise() cube(well, center=true);
            vee(30, block);
        }
    }
    translate(origin) {
        shell(block);
        %raise() raise(cards[0]/2-block[2]/2)
            rotate([0, 90, 90]) cube(cards, center=true);
    }
}

board = 2.25;
Rhex = 3/4 * 25.4;  // center to vertex
function hex_grid(x, y) = [Rhex*x, sin(60)*Rhex*y];
module map_tile_poly(center=false) {
    grid = [
        [2, 0], [2.5, 1], [2, 2], [1, 2], [0.5, 3], [-0.5, 3],
        [-1, 2], [-2, 2], [-2.5, 1], [-3.5, 1], [-4, 0], [-5, 0],
        [-5.5, -1], [-5, -2], [-4, -2], [-3.5, -3], [-2.5, -3], [-2, -2],
        [-1, -2], [-0.5, -3], [0.5, -3], [1, -2], [2, -2], [2.5, -1],
    ];
    tile = [for (i=grid) hex_grid(i[0], i[1])];
    origin = center ? [0, 0] : hex_grid(5.5, 3);
    translate(origin) polygon(tile);
}
module map_tile(n=1, center=false) {
    linear_extrude(board*n, center=center) map_tile_poly();
}

module map_tile_box(n=1, center=false) {
    h = ceil(board * (n + 3/4) + floor0);
    origin = center ? [0, 0] : [1, 1] * (1+wall0);
    translate(origin) difference() {
        linear_extrude(h, center=center)
            offset(r=1+wall0) map_tile_poly(center);
        raise() linear_extrude(h, center=center)
            offset(r=1) map_tile_poly(center);
    }
    %raise() map_tile(n);
}

union() {
    %interior();
    rotate(180) focus_frame();
    for (x=[-144-gap0, -48, 48+gap0]) for (y=[-58, -37+gap0])
        translate([x, y, 0]) deck_box();
    rotate(-45)
    translate([interior[0]/2-2-2*wall0, -interior[1]/2] - hex_grid(8, 0)) {
        map_tile_box(16);
        raise(40+1) map_tile_box(5);
    }
}
