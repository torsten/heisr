#!/usr/bin/env ruby

require "#{File.expand_path(File.dirname(__FILE__))}/heisr_core.rb"


puts Heisr.generate_atom(Time.now.utc.xmlschema, Heisr.fetch_entries)
