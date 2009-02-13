#!/usr/bin/env ruby
PROJECT_ROOT = ARGV[0]   # Where to browse for images
VIM_SERVERNAME = ARGV[1] # Send text to which vim
if PLATFORM =~ /cygwin/
    ENV['TM_BUNDLE_SUPPORT'] = '/cygdrive/c/Program Files/Vim/vimfiles/tools/ImageBrowser'
else
    ENV['TM_BUNDLE_SUPPORT'] = ENV['HOME'] + '/.vim/tools/ImageBrowser'
end
RESOURCES_DIR = "#{ENV['TM_BUNDLE_SUPPORT']}/Resources" # Where to find ImageBrowser's images
require "#{ENV['TM_BUNDLE_SUPPORT']}/image_size.rb"
require 'erb'

erb = ERB.new(IO.read("#{ENV['TM_BUNDLE_SUPPORT']}/Resources/browser.rhtml"))
erb.run
