union() {
  union() {
    union() {
      union() {
        union() {
          union() {
            union() {
              union() {
                translate([-0.17, 0, 0]) {
                  translate([0, -0.12, 0]) {
                    translate([0, 0, 0.0]) {
                      cube([0.16, 0.26, 0.12]);
                    }
                  }
                }
                translate([1.0e-2, 0, 0]) {
                  translate([0, -0.12, 0]) {
                    translate([0, 0, 0.0]) {
                      cube([0.16, 0.26, 0.12]);
                    }
                  }
                }
              }
              translate([0, 0, 1.02]) {
                cylinder(h = 0.1, r = 0.14, $fn = 6);
              }
            }
            translate([0, 0, 1.0]) {
              cylinder(h = 3.0e-2, r = 0.17, $fn = 6);
            }
          }
          translate([-0.15, 0, 0]) {
            translate([0, -0.3, 0]) {
              translate([0, 0, 0.52]) {
                cube([0.3, 0.16, 0.3]);
              }
            }
          }
        }
        rotate([0, 0, 25.0]) {
          translate([0, 8.0e-2, 0]) {
            translate([0, 0, 0.66]) {
              rotate([-90.0, 0, 0]) {
                cylinder(h = 0.55, r = 4.5e-2, $fn = 6);
              }
            }
          }
        }
      }
      rotate([0, 0, 25.0]) {
        translate([-4.5e-2, 0, 0]) {
          translate([0, -0.22, 0]) {
            translate([0, 0, 0.58]) {
              cube([9.0e-2, 0.32, 0.13]);
            }
          }
        }
      }
    }
    rotate([0, 0, 25.0]) {
      translate([-2.5e-2, 0, 0]) {
        translate([0, 0.12, 0]) {
          translate([0, 0, 0.54]) {
            cube([5.0e-2, 6.0e-2, 0.14]);
          }
        }
      }
    }
  }
  rotate([0, 0, 25.0]) {
    translate([-2.5e-2, 0, 0]) {
      translate([0, 0.0, 0]) {
        translate([0, 0, 0.55]) {
          cube([5.0e-2, 5.0e-2, 0.12]);
        }
      }
    }
  }
}
$fn = 50;