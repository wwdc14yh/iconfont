require 'pathname'
require 'rexml/document'
include REXML

class GeneraateFile
    attr_accessor :source_file
    attr_accessor :destination_header
    attr_accessor :destination_implementation

    def initialize(source_file, destination_header, destination_implementation)
        @source_file = source_file
        @destination_header = destination_header
        @destination_implementation = destination_implementation
    end

    def generateHFile(iconfontMap)
        header = author + '//  Created by AutoCoding on ' + Time.new.strftime('%Y/%m/%d') + ".\n" + headerPropertry

        iconfontMap.keys.each do |key|
            header = header + '@property (readonly) NSString *icon' + key.to_s + ";\n\n"
        end
        header += '@end'
        header
    end

    def generateMFile(iconFontName, iconfontMap)
        implementation = author + '//  Created by AutoCoding on ' + Time.new.strftime('%Y/%m/%d') + ".\n" + implementationFile + '    UIFont *font = [UIFont fontWithName:@"' + iconFontName + '" size:size];' + "\n"
        implementation += "
          return font;
      }\n \n"

        iconfontMap.each do |key, value|
            implementation = implementation + '- (NSString *)icon' + key.to_s + " {\n"
            implementation = implementation + '    return @"\\U0000' + value + '";' + "\n}\n\n"
        end
        implementation += '@end'
        implementation
    end

    def author
        string = <<-EOF
//
//  YppIconFont.h
//  AutoCoding
//
EOF
    end

    def headerPropertry
        string = <<-HEADER
//  Copyright © 2017年 olinone. All rights reserved.
//
#import <Foundation/Foundation.h>
@import CoreText;

#define ICONFONT [YppIconFont shareInstance]

@interface YppIconFont : NSObject

+ (instancetype)shareInstance;

+ (UIFont *)iconFontWithSize:(CGFloat)size;
HEADER
    end

    def implementationFile
        implementation = <<-EOB
//  Copyright © 2016年 olinone. All rights reserved.
//

#import "YppIconFont.h"

@implementation YppIconFont

+ (instancetype)shareInstance {
    static YppIconFont *iconFont = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iconFont = [YppIconFont new];
    });
    return iconFont;
}

+ (UIFont *)iconFontWithSize:(CGFloat)size {
EOB
    end

    def writeToFile(text, path)
        hio = File.open(path, 'w+')
        hio.puts(text)
        hio.close
    end
end

class Check
    def helpString
        'Usage: svg2oc <svgFile> [-out <outpath>]'
    end

    def safeCheck
        if ARGV.count < 1 || ARGV.count != 1 && ARGV.count != 3
            puts helpString
            exit(1)
        end

        unless File.exist?(ARGV[0])
            puts 'No such file: ' + ARGV[0]
            exit(1)
        end
    end
end

class ParserSVG
    attr_accessor :svg_file
    def initialize(svg_file)
        @svg_file = svg_file
    end

    def beginParese
        doc = Document.new(File.new(@svg_file))
        elements = {}
        XPath.each(doc, '//glyph') do |e|
            next unless e.attributes['horiz-adv-x'] == '1024'
            glyph_name = e.attributes['glyph-name']
            glyph_symbol = jointParemeter(glyph_name)
            glyph_code = e.attributes['unicode'].ord.to_s(16)
            elements[glyph_symbol] = glyph_code
        end
        elements
    end

    def jointParemeter(val)
        if val.include? '-'
            names = val.split('-')
            jointString = ''
            names.each do |name|
                jointString.concat(name.capitalize)
            end
            return jointString
        end
        val.capitalize
    end
end

# main
check = Check.new
check.safeCheck

parser = ParserSVG.new(ARGV[0])

source_file = ARGV[0]
io = File.open(source_file)
icon_font_map = parser.beginParese
io.close

# hfile
hfilepath = File.dirname(__FILE__) + '/YppIconFont.h'
mfilepath = File.dirname(__FILE__) + '/YppIconFont.m'
generate = GeneraateFile.new(source_file, hfilepath, mfilepath)
generate.writeToFile(generate.generateHFile(icon_font_map), generate.destination_header)
generate.writeToFile(generate.generateMFile('iconfont', icon_font_map), generate.destination_implementation)

puts 'Done!'

