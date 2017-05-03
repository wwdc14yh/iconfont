#! /bin/sh/ruby
require 'pathname'
require 'rexml/document'
include REXML

$outpath = File.dirname(__FILE__)

def paramCheck

  helpString = <<-EOB
  Usage: svg2oc <svgFile> [-out <outpath>]
  EOB

  if ARGV.count < 1 then
    puts helpString
    exit(1)
  end

  if ARGV.count != 1  && ARGV.count != 3  then
    puts "Param Error!"
    puts helpString
    exit(1)
  end

  if !File.exist?(ARGV[0]) then
    puts "No such file: " + ARGV[0]
    exit(1)
  end

  if ARGV.count == 3 then
    if ARGV[1].to_s == "-out" then
      $outpath = ARGV[2]
      if !File.exist?($outpath) then
        puts "No such directory: " + $outpath
        exit(1)
      end
    end
  end
end

def parserXML
  xml_file = ARGV[0]
  elements = Hash.new
  doc = Document.new(File.new(xml_file))

  XPath.each(doc,'//glyph') {|e|
    if e.attributes.count == 3
      glyph_name = e.attributes['glyph-name']
      glyph_symbol = jointParemeter(glyph_name)
      glyph_code = e.attributes['unicode'].ord.to_s(16)
      elements[glyph_symbol] = glyph_code
    end
  }
  return elements
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

  return val.capitalize
end

def generateHFile(iconfontMap)
  string1 = <<-EOB
//
//  IconFont.h
//  AutoCoding
//
  EOB

  string2 = <<-EOB
//  Copyright © 2017年 olinone. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreText;

#define ICONFONT [YppIconFont shareInstance]

@interface YppIconFont : NSObject

+ (instancetype)shareInstance;

+ (UIFont *)iconFontWithSize:(CGFloat)size;
EOB

  hString = string1 + "//  Created by AutoCoding on " + Time.new.strftime("%Y/%m/%d") + ".\n" + string2

  iconfontMap.keys.each do |key|
    hString = hString + "@property (readonly) NSString *icon" + key.to_s + ";\n\n"
  end

  hString = hString + "@end"

  return hString
end

def generateMFile(iconFontName, iconfontMap)
  iconFont = "iconfont"
  string1 = <<-EOB
//
//  YppIconFont.m
//  AutoCoding
//
  EOB

  string2 = <<-EOB
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

  mString = string1 + "//  Created by AutoCoding on " + Time.new.strftime("%Y/%m/%d") + ".\n" + string2 + "    UIFont *font = [UIFont fontWithName:@\"" + iconFontName + "\" size:size];" + "\n"
  mString = mString + "
    return font;
}\n \n"

  iconfontMap.each { |key, value|
    mString = mString + "- (NSString *)icon" + key.to_s + " {\n";
    mString = mString + "    return @\"\\U0000" + value + "\";" + "\n}\n\n"
  }

  mString = mString + "@end"

  return mString
end


def putStringToFile(text, path)
  hio = File.open(path, "w+")
  hio.puts(text)
  hio.close
end

# main
paramCheck

inpath = ARGV[0]
io = File.open(inpath)
icon_font_map = parserXML
io.close

unless icon_font_map
  p 'parse error'
  exit(0)
end
# hfile
hfilepath = $outpath+"/YppIconFont.h"
putStringToFile(generateHFile(icon_font_map), hfilepath)

# mfile
iconfontName = 'iconfont'
mfilepath = $outpath+"/YppIconFont.m"
putStringToFile(generateMFile(iconfontName, icon_font_map), mfilepath)

puts "Done!"
