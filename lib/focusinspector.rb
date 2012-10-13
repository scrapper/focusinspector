#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

require 'rubygems'
require 'tempfile'
require 'optparse'
require 'RMagick'
require 'mini_exiftool'

require 'focusinspector/FocusInspector'

FocusInspector.new(ARGV)

