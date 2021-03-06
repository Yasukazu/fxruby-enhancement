# coding: utf-8

=begin rdoc
= Scrape RDoc from FXRuby
We need to scrape that and convert it to a form
suitable for static introspection of the FXRuby
API, with the implied parameters and their defaults
for the many classes in FXRuby
=end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

SOURCES = File.expand_path("../fxruby/rdoc-sources", File.dirname(__FILE__))
SRC_DEFS = File.expand_path("../fxruby/fox-includes/fxdefs.h", File.dirname(__FILE__))

TARGET = File.expand_path("../lib/fxruby-enhancement/api-mapper.rb", File.dirname(__FILE__))
TEMPLATE = File.expand_path("api-mapper.rb.erb", File.dirname(TARGET))

TARGET_RGB = File.expand_path("../lib/fxruby-enhancement/color-mapper.rb", File.dirname(__FILE__))
TEMPLATE_RGB = File.expand_path("color-mapper.rb.erb", File.dirname(TARGET_RGB))

File.delete TARGET unless not File.exists? TARGET
File.delete TARGET_RGB unless not File.exists? TARGET_RGB
File.open(TARGET, 'w') {}
File.open(TARGET_RGB, 'w') {}

require 'fxruby-enhancement'
require 'erb'
require 'pp'

# Indeed we parse the rdoc-sources to glean the actual API
# for FXRuby, since live introspection of the actual API
# is underdeterimed, being a wrapper for the underlying C++
# library, which does things, unsurpringly, in a very C++
# way. And so, I fight evil with evil here. So let the evil
# begin. 

last_class = nil
API = Dir.entries(SOURCES)                   
      .select{ |f| /^FX.*\.rb$/ =~ f  }
      .sort
      .map{ |f| File.expand_path(f, SOURCES) }
      .map{ |f| File.open(f, "r").readlines }
      .flatten
      .reject{ |s| /^\s*#/ =~ s }
      .map{ |s| s
            .split(/#|;/).first
            .split('def').last
            .strip }
      .select{ |s| /class|initialize(?!d)/ =~ s }
      .map{ |s| s.split(/ |\(/, 2) }
      .map{ |type, rest| [type.to_sym, rest] }
      .map{ |type, rest| case type
                         when :class
                           [type, rest.split(/\b*<\b*/)]
                         when :initialize
                           [type,
                            (rest.nil?) ? nil
                            : rest.chop.scan(/(?:\(.*?\)|[^,])+/)
                              .map{ |s| s
                                    .strip
                                    .split('=')}]
                         else
                           raise "unknown type #{type} for #{rest}"
                         end }
      .map{ |type, inf| [type,
                         case type
                         when :class
                           inf.map{ |s| s.strip.to_sym}
                         when :initialize
                           inf.map{ |var, deft|
                             [var.to_sym, deft] }.to_h unless inf.nil?
                         end ]}
      .group_by{ |type, inf| case type
                             when :class
                               last_class = inf.first
                             when :initialize
                               last_class
                             end }
      .map{ |klass, details| [klass,
                              details.group_by{ |type, inf| type }]}
      .map{ |klass, details| [klass,
                              details.map{ |type, inf| case type
                                                      when :class
                                                        inf.last
                                                      when :initialize
                                                        [type, inf.map{ |t, h| h }]
                                                      end }.to_h
                             ]}
      .to_h

# Scan for Selectors
File.open(SRC_DEFS, 'r') do |fd|
  SEL = fd.readlines
        .select{ |s| s =~ /SEL_/ }
        .map{ |s| /(SEL_)([A-Z_]+),(.*)/.match s }
        .compact
        .map{ |md| [md[1], md[2], /\b*\/\/\/(.*)/.match(md[3])] }
        .map{ |s, f, c| [s+f, f.downcase.to_sym, c.nil? ? '' : c[1].strip] }
end

# Now that we have the entire FXRuby API description,
# we now rely on the template to flesh out and create
# the DSL. Total insanity that I would attempt to use
# metaprograming to autogeneate a DSL. No worries. I've
# done worse. :p I aplogize for the apperent "ugliness"
# in this approach, but desperate times call for desperate
# measures...
#
# NOTE WELL
#   Please bear in mind that in the API structure, you will
#   see both nil and "nil" listed as default parameters. The
#   nil indicates a required parameter, whereas "nil" indicates
#   a default value for a parameter. Perhaps I should've gone
#   through the extra step of slapping in :required for
#   the nil entries, but getting the logic above was tricky
#   enough, and only those maintaning THIS code will ever
#   need be concerned about the distinctions.

File.open(TEMPLATE, 'r') do |template|
  File.open(TARGET, 'w') do |target|
    @api = API
    @sel = SEL
    target.write ERB.new(template.read).result(binding)
  end
end

FXC = {
  GhostWhite: "Fox.FXRGB(248, 248, 255)",
  WhiteSmoke: "Fox.FXRGB(245, 245, 245)",
  FloralWhite: "Fox.FXRGB(255, 250, 240)",
  OldLace: "Fox.FXRGB(253, 245, 230)",
  AntiqueWhite: "Fox.FXRGB(250, 235, 215)",
  PapayaWhip: "Fox.FXRGB(255, 239, 213)",
  BlanchedAlmond: "Fox.FXRGB(255, 235, 205)",
  PeachPuff: "Fox.FXRGB(255, 218, 185)",
  NavajoWhite: "Fox.FXRGB(255, 222, 173)",
  LemonChiffon: "Fox.FXRGB(255, 250, 205)",
  MintCream: "Fox.FXRGB(245, 255, 250)",
  AliceBlue: "Fox.FXRGB(240, 248, 255)",
  LavenderBlush: "Fox.FXRGB(255, 240, 245)",
  MistyRose: "Fox.FXRGB(255, 228, 225)",
  DarkSlateGray: "Fox.FXRGB( 47,  79,  79)",
  DarkSlateGrey: "Fox.FXRGB( 47,  79,  79)",
  DimGray: "Fox.FXRGB(105, 105, 105)",
  DimGrey: "Fox.FXRGB(105, 105, 105)",
  SlateGray: "Fox.FXRGB(112, 128, 144)",
  SlateGrey: "Fox.FXRGB(112, 128, 144)",
  LightSlateGrey: "Fox.FXRGB(119, 136, 153)",
  LightGray: "Fox.FXRGB(211, 211, 211)",
  MidnightBlue: "Fox.FXRGB( 25,  25, 112)",
  NavyBlue: "Fox.FXRGB(  0,   0, 128)",
  CornflowerBlue: "Fox.FXRGB(100, 149, 237)",
  DarkSlateBlue: "Fox.FXRGB( 72,  61, 139)",
  SlateBlue: "Fox.FXRGB(106,  90, 205)",
  MediumSlateBlue: "Fox.FXRGB(123, 104, 238)",
  LightSlateBlue: "Fox.FXRGB(132, 112, 255)",
  MediumBlue: "Fox.FXRGB(  0,   0, 205)",
  RoyalBlue: "Fox.FXRGB( 65, 105, 225)",
  DodgerBlue: "Fox.FXRGB( 30, 144, 255)",
  DeepSkyBlue: "Fox.FXRGB(  0, 191, 255)",
  SkyBlue: "Fox.FXRGB(135, 206, 235)",
  LightSkyBlue: "Fox.FXRGB(135, 206, 250)",
  SteelBlue: "Fox.FXRGB( 70, 130, 180)",
  LightSteelBlue: "Fox.FXRGB(176, 196, 222)",
  LightBlue: "Fox.FXRGB(173, 216, 230)",
  PowderBlue: "Fox.FXRGB(176, 224, 230)",
  PaleTurquoise: "Fox.FXRGB(175, 238, 238)",
  DarkTurquoise: "Fox.FXRGB(  0, 206, 209)",
  MediumTurquoise: "Fox.FXRGB( 72, 209, 204)",
  LightCyan: "Fox.FXRGB(224, 255, 255)",
  CadetBlue: "Fox.FXRGB( 95, 158, 160)",
  MediumAquamarine: "Fox.FXRGB(102, 205, 170)",
  DarkGreen: "Fox.FXRGB(  0, 100,   0)",
  DarkOliveGreen: "Fox.FXRGB( 85, 107,  47)",
  DarkSeaGreen: "Fox.FXRGB(143, 188, 143)",
  SeaGreen: "Fox.FXRGB( 46, 139,  87)",
  MediumSeaGreen: "Fox.FXRGB( 60, 179, 113)",
  LightSeaGreen: "Fox.FXRGB( 32, 178, 170)",
  PaleGreen: "Fox.FXRGB(152, 251, 152)",
  SpringGreen: "Fox.FXRGB(  0, 255, 127)",
  LawnGreen: "Fox.FXRGB(124, 252,   0)",
  MediumSpringGreen: "Fox.FXRGB(  0, 250, 154)",
  GreenYellow: "Fox.FXRGB(173, 255,  47)",
  LimeGreen: "Fox.FXRGB( 50, 205,  50)",
  YellowGreen: "Fox.FXRGB(154, 205,  50)",
  ForestGreen: "Fox.FXRGB( 34, 139,  34)",
  OliveDrab: "Fox.FXRGB(107, 142,  35)",
  DarkKhaki: "Fox.FXRGB(189, 183, 107)",
  PaleGoldenrod: "Fox.FXRGB(238, 232, 170)",
  LightGoldenrodYellow: "Fox.FXRGB(250, 250, 210)",
  LightYellow: "Fox.FXRGB(255, 255, 224)",
  LightGoldenrod: "Fox.FXRGB(238, 221, 130)",
  DarkGoldenrod: "Fox.FXRGB(184, 134,  11)",
  RosyBrown: "Fox.FXRGB(188, 143, 143)",
  IndianRed: "Fox.FXRGB(205,  92,  92)",
  SaddleBrown: "Fox.FXRGB(139,  69,  19)",
  SandyBrown: "Fox.FXRGB(244, 164,  96)",
  DarkSalmon: "Fox.FXRGB(233, 150, 122)",
  LightSalmon: "Fox.FXRGB(255, 160, 122)",
  DarkOrange: "Fox.FXRGB(255, 140,   0)",
  LightCoral: "Fox.FXRGB(240, 128, 128)",
  OrangeRed: "Fox.FXRGB(255,  69,   0)",
  HotPink: "Fox.FXRGB(255, 105, 180)",
  DeepPink: "Fox.FXRGB(255,  20, 147)",
  LightPink: "Fox.FXRGB(255, 182, 193)",
  PaleVioletRed: "Fox.FXRGB(219, 112, 147)",
  MediumVioletRed: "Fox.FXRGB(199,  21, 133)",
  VioletRed: "Fox.FXRGB(208,  32, 144)",
  MediumOrchid: "Fox.FXRGB(186,  85, 211)",
  DarkOrchid: "Fox.FXRGB(153,  50, 204)",
  DarkViolet: "Fox.FXRGB(148,   0, 211)",
  BlueViolet: "Fox.FXRGB(138,  43, 226)",
  MediumPurple: "Fox.FXRGB(147, 112, 219)",
  AntiqueWhite1: "Fox.FXRGB(255, 239, 219)",
  AntiqueWhite2: "Fox.FXRGB(238, 223, 204)",
  AntiqueWhite3: "Fox.FXRGB(205, 192, 176)",
  AntiqueWhite4: "Fox.FXRGB(139, 131, 120)",
  PeachPuff1: "Fox.FXRGB(255, 218, 185)",
  PeachPuff2: "Fox.FXRGB(238, 203, 173)",
  PeachPuff3: "Fox.FXRGB(205, 175, 149)",
  PeachPuff4: "Fox.FXRGB(139, 119, 101)",
  NavajoWhite1: "Fox.FXRGB(255, 222, 173)",
  NavajoWhite2: "Fox.FXRGB(238, 207, 161)",
  NavajoWhite3: "Fox.FXRGB(205, 179, 139)",
  NavajoWhite4: "Fox.FXRGB(139, 121,  94)",
  LemonChiffon1: "Fox.FXRGB(255, 250, 205)",
  LemonChiffon2: "Fox.FXRGB(238, 233, 191)",
  LemonChiffon3: "Fox.FXRGB(205, 201, 165)",
  LemonChiffon4: "Fox.FXRGB(139, 137, 112)",
  LavenderBlush1: "Fox.FXRGB(255, 240, 245)",
  LavenderBlush2: "Fox.FXRGB(238, 224, 229)",
  LavenderBlush3: "Fox.FXRGB(205, 193, 197)",
  LavenderBlush4: "Fox.FXRGB(139, 131, 134)",
  MistyRose1: "Fox.FXRGB(255, 228, 225)",
  MistyRose2: "Fox.FXRGB(238, 213, 210)",
  MistyRose3: "Fox.FXRGB(205, 183, 181)",
  MistyRose4: "Fox.FXRGB(139, 125, 123)",
  SlateBlue1: "Fox.FXRGB(131, 111, 255)",
  SlateBlue2: "Fox.FXRGB(122, 103, 238)",
  SlateBlue3: "Fox.FXRGB(105,  89, 205)",
  SlateBlue4: "Fox.FXRGB( 71,  60, 139)",
  RoyalBlue1: "Fox.FXRGB( 72, 118, 255)",
  RoyalBlue2: "Fox.FXRGB( 67, 110, 238)",
  RoyalBlue3: "Fox.FXRGB( 58,  95, 205)",
  RoyalBlue4: "Fox.FXRGB( 39,  64, 139)",
  DodgerBlue1: "Fox.FXRGB( 30, 144, 255)",
  DodgerBlue2: "Fox.FXRGB( 28, 134, 238)",
  DodgerBlue3: "Fox.FXRGB( 24, 116, 205)",
  DodgerBlue4: "Fox.FXRGB( 16,  78, 139)",
  SteelBlue1: "Fox.FXRGB( 99, 184, 255)",
  SteelBlue2: "Fox.FXRGB( 92, 172, 238)",
  SteelBlue3: "Fox.FXRGB( 79, 148, 205)",
  SteelBlue4: "Fox.FXRGB( 54, 100, 139)",
  DeepSkyBlue1: "Fox.FXRGB(  0, 191, 255)",
  DeepSkyBlue2: "Fox.FXRGB(  0, 178, 238)",
  DeepSkyBlue3: "Fox.FXRGB(  0, 154, 205)",
  DeepSkyBlue4: "Fox.FXRGB(  0, 104, 139)",
  SkyBlue1: "Fox.FXRGB(135, 206, 255)",
  SkyBlue2: "Fox.FXRGB(126, 192, 238)",
  SkyBlue3: "Fox.FXRGB(108, 166, 205)",
  SkyBlue4: "Fox.FXRGB( 74, 112, 139)",
  LightSkyBlue1: "Fox.FXRGB(176, 226, 255)",
  LightSkyBlue2: "Fox.FXRGB(164, 211, 238)",
  LightSkyBlue3: "Fox.FXRGB(141, 182, 205)",
  LightSkyBlue4: "Fox.FXRGB( 96, 123, 139)",
  SlateGray1: "Fox.FXRGB(198, 226, 255)",
  SlateGray2: "Fox.FXRGB(185, 211, 238)",
  SlateGray3: "Fox.FXRGB(159, 182, 205)",
  SlateGray4: "Fox.FXRGB(108, 123, 139)",
  LightSteelBlue1: "Fox.FXRGB(202, 225, 255)",
  LightSteelBlue2: "Fox.FXRGB(188, 210, 238)",
  LightSteelBlue3: "Fox.FXRGB(162, 181, 205)",
  LightSteelBlue4: "Fox.FXRGB(110, 123, 139)",
  LightBlue1: "Fox.FXRGB(191, 239, 255)",
  LightBlue2: "Fox.FXRGB(178, 223, 238)",
  LightBlue3: "Fox.FXRGB(154, 192, 205)",
  LightBlue4: "Fox.FXRGB(104, 131, 139)",
  LightCyan1: "Fox.FXRGB(224, 255, 255)",
  LightCyan2: "Fox.FXRGB(209, 238, 238)",
  LightCyan3: "Fox.FXRGB(180, 205, 205)",
  LightCyan4: "Fox.FXRGB(122, 139, 139)",
  PaleTurquoise1: "Fox.FXRGB(187, 255, 255)",
  PaleTurquoise2: "Fox.FXRGB(174, 238, 238)",
  PaleTurquoise3: "Fox.FXRGB(150, 205, 205)",
  PaleTurquoise4: "Fox.FXRGB(102, 139, 139)",
  CadetBlue1: "Fox.FXRGB(152, 245, 255)",
  CadetBlue2: "Fox.FXRGB(142, 229, 238)",
  CadetBlue3: "Fox.FXRGB(122, 197, 205)",
  CadetBlue4: "Fox.FXRGB( 83, 134, 139)",
  DarkSlateGray1: "Fox.FXRGB(151, 255, 255)",
  DarkSlateGray2: "Fox.FXRGB(141, 238, 238)",
  DarkSlateGray3: "Fox.FXRGB(121, 205, 205)",
  DarkSlateGray4: "Fox.FXRGB( 82, 139, 139)",
  DarkSeaGreen1: "Fox.FXRGB(193, 255, 193)",
  DarkSeaGreen2: "Fox.FXRGB(180, 238, 180)",
  DarkSeaGreen3: "Fox.FXRGB(155, 205, 155)",
  DarkSeaGreen4: "Fox.FXRGB(105, 139, 105)",
  SeaGreen1: "Fox.FXRGB( 84, 255, 159)",
  SeaGreen2: "Fox.FXRGB( 78, 238, 148)",
  SeaGreen3: "Fox.FXRGB( 67, 205, 128)",
  SeaGreen4: "Fox.FXRGB( 46, 139,  87)",
  PaleGreen1: "Fox.FXRGB(154, 255, 154)",
  PaleGreen2: "Fox.FXRGB(144, 238, 144)",
  PaleGreen3: "Fox.FXRGB(124, 205, 124)",
  PaleGreen4: "Fox.FXRGB( 84, 139,  84)",
  SpringGreen1: "Fox.FXRGB(  0, 255, 127)",
  SpringGreen2: "Fox.FXRGB(  0, 238, 118)",
  SpringGreen3: "Fox.FXRGB(  0, 205, 102)",
  SpringGreen4: "Fox.FXRGB(  0, 139,  69)",
  OliveDrab1: "Fox.FXRGB(192, 255,  62)",
  OliveDrab2: "Fox.FXRGB(179, 238,  58)",
  OliveDrab3: "Fox.FXRGB(154, 205,  50)",
  OliveDrab4: "Fox.FXRGB(105, 139,  34)",
  DarkOliveGreen1: "Fox.FXRGB(202, 255, 112)",
  DarkOliveGreen2: "Fox.FXRGB(188, 238, 104)",
  DarkOliveGreen3: "Fox.FXRGB(162, 205,  90)",
  DarkOliveGreen4: "Fox.FXRGB(110, 139,  61)",
  LightGoldenrod1: "Fox.FXRGB(255, 236, 139)",
  LightGoldenrod2: "Fox.FXRGB(238, 220, 130)",
  LightGoldenrod3: "Fox.FXRGB(205, 190, 112)",
  LightGoldenrod4: "Fox.FXRGB(139, 129,  76)",
  LightYellow1: "Fox.FXRGB(255, 255, 224)",
  LightYellow2: "Fox.FXRGB(238, 238, 209)",
  LightYellow3: "Fox.FXRGB(205, 205, 180)",
  LightYellow4: "Fox.FXRGB(139, 139, 122)",
  DarkGoldenrod1: "Fox.FXRGB(255, 185,  15)",
  DarkGoldenrod2: "Fox.FXRGB(238, 173,  14)",
  DarkGoldenrod3: "Fox.FXRGB(205, 149,  12)",
  DarkGoldenrod4: "Fox.FXRGB(139, 101,   8)",
  RosyBrown1: "Fox.FXRGB(255, 193, 193)",
  RosyBrown2: "Fox.FXRGB(238, 180, 180)",
  RosyBrown3: "Fox.FXRGB(205, 155, 155)",
  RosyBrown4: "Fox.FXRGB(139, 105, 105)",
  IndianRed1: "Fox.FXRGB(255, 106, 106)",
  IndianRed2: "Fox.FXRGB(238,  99,  99)",
  IndianRed3: "Fox.FXRGB(205,  85,  85)",
  IndianRed4: "Fox.FXRGB(139,  58,  58)",
  LightSalmon1: "Fox.FXRGB(255, 160, 122)",
  LightSalmon2: "Fox.FXRGB(238, 149, 114)",
  LightSalmon3: "Fox.FXRGB(205, 129,  98)",
  LightSalmon4: "Fox.FXRGB(139,  87,  66)",
  DarkOrange1: "Fox.FXRGB(255, 127,   0)",
  DarkOrange2: "Fox.FXRGB(238, 118,   0)",
  DarkOrange3: "Fox.FXRGB(205, 102,   0)",
  DarkOrange4: "Fox.FXRGB(139,  69,   0)",
  OrangeRed1: "Fox.FXRGB(255,  69,   0)",
  OrangeRed2: "Fox.FXRGB(238,  64,   0)",
  OrangeRed3: "Fox.FXRGB(205,  55,   0)",
  OrangeRed4: "Fox.FXRGB(139,  37,   0)",
  DeepPink1: "Fox.FXRGB(255,  20, 147)",
  DeepPink2: "Fox.FXRGB(238,  18, 137)",
  DeepPink3: "Fox.FXRGB(205,  16, 118)",
  DeepPink4: "Fox.FXRGB(139,  10,  80)",
  HotPink1: "Fox.FXRGB(255, 110, 180)",
  HotPink2: "Fox.FXRGB(238, 106, 167)",
  HotPink3: "Fox.FXRGB(205,  96, 144)",
  HotPink4: "Fox.FXRGB(139,  58,  98)",
  LightPink1: "Fox.FXRGB(255, 174, 185)",
  LightPink2: "Fox.FXRGB(238, 162, 173)",
  LightPink3: "Fox.FXRGB(205, 140, 149)",
  LightPink4: "Fox.FXRGB(139,  95, 101)",
  PaleVioletRed1: "Fox.FXRGB(255, 130, 171)",
  PaleVioletRed2: "Fox.FXRGB(238, 121, 159)",
  PaleVioletRed3: "Fox.FXRGB(205, 104, 137)",
  PaleVioletRed4: "Fox.FXRGB(139,  71,  93)",
  VioletRed1: "Fox.FXRGB(255,  62, 150)",
  VioletRed2: "Fox.FXRGB(238,  58, 140)",
  VioletRed3: "Fox.FXRGB(205,  50, 120)",
  VioletRed4: "Fox.FXRGB(139,  34,  82)",
  MediumOrchid1: "Fox.FXRGB(224, 102, 255)",
  MediumOrchid2: "Fox.FXRGB(209,  95, 238)",
  MediumOrchid3: "Fox.FXRGB(180,  82, 205)",
  MediumOrchid4: "Fox.FXRGB(122,  55, 139)",
  DarkOrchid1: "Fox.FXRGB(191,  62, 255)",
  DarkOrchid2: "Fox.FXRGB(178,  58, 238)",
  DarkOrchid3: "Fox.FXRGB(154,  50, 205)",
  DarkOrchid4: "Fox.FXRGB(104,  34, 139)",
  MediumPurple1: "Fox.FXRGB(171, 130, 255)",
  MediumPurple2: "Fox.FXRGB(159, 121, 238)",
  MediumPurple3: "Fox.FXRGB(137, 104, 205)",
  MediumPurple4: "Fox.FXRGB( 93,  71, 139)",
  DarkGrey: "Fox.FXRGB(169, 169, 169)",
  DarkGray: "Fox.FXRGB(169, 169, 169)",
  DarkBlue: "Fox.FXRGB(0  ,   0, 139)",
  DarkCyan: "Fox.FXRGB(0  , 139, 139)",
  DarkMagenta: "Fox.FXRGB(139,   0, 139)",
  DarkRed: "Fox.FXRGB(139,   0,   0)",
  LightGreen: "Fox.FXRGB(144, 238, 144)",
  White: "Fox.FXRGB(255, 255, 255)",
  Black: "Fox.FXRGB(0, 0, 0)",
  Red: "Fox.FXRGB(255, 0, 0)",
  Pink: "Fox.FXRGB(255, 175, 175)",
  Orange: "Fox.FXRGB(255, 200, 0)",
  Yellow: "Fox.FXRGB(255, 255, 0)",
  Green: "Fox.FXRGB(0, 255, 0)",
  Magenta: "Fox.FXRGB(255, 0, 255)",
  Cyan: "Fox.FXRGB(0, 255, 255)",
  Blue: "Fox.FXRGB(0, 0, 255) ",
}

File.open(TEMPLATE_RGB, 'r') do |template|
  File.open(TARGET_RGB, 'w') do |target|
    @fxc = FXC
    target.write ERB.new(template.read).result(binding)
  end
end
