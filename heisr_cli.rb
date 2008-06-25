require 'heisr_core'

puts Heisr.generate_atom(Time.now.utc.xmlschema, Heisr.fetch_entries)
