%w.time rexml/document ubygems builder hpricot open-uri..
each{|_|require _}


module Heisr
  
  FEEDS = %w#
    http://www.heise.de/newsticker/heise-atom.xml
    http://www.heise.de/open/news/news-atom.xml
    http://www.heise.de/mobil/newsticker/heise-atom.xml
    http://www.heise.de/security/news/news-atom.xml
  #

  # FEEDS = %w#
  #   newsticker-atom.xml
  #   security-atom.xml
  # #
  
  RELEASE = 2
  
  CACHE_FILE = "#{File.expand_path(File.dirname(__FILE__))}/heisr.cache"
  
  
  def self.fetch_entries
    cache = Marshal.load(File.read(Heisr::CACHE_FILE)) rescue {}
    current_ids = []
    
    entries = 
    # Over all FEEDs
    Heisr::FEEDS.map do |feed|
      doc = REXML::Document.new(open(feed))
      
      # Create a Hash for every feed with "meldung_id => meldung_data_as_hash"
      Hash[
        *doc.elements.collect("/feed/entry") do |entry|
          link = entry.elements['link'].attributes['href']
          
          [ link[%r{/meldung/(\d+)}, 1].to_i,
            {
              :title => entry.elements['title'].text,
              :link => link,
              :id => entry.elements['id'].text,
              :updated => entry.elements['updated'].text,
              :source => link[%r{http://www.heise.de/(.+?)/}, 1],
            }
          ]
        end.flatten
      ]
    end.
    # This gives an Array of Hashes containing the entries
    # Now lets eliminate the double entries
    inject({}) do |accu, hsh|
      accu.merge hsh
    end.to_a.
    # Now lets sort this stuff by meldungs id
    sort do |a, b|
      a[0] <=> b[0]
    end.
    # And now make a nice array for the view
    map do |entry|
      cache_key = "#{entry[0]}:#{entry[1][:updated]}".to_sym
      current_ids << entry[0]
      
      if not cache[cache_key]
        $stderr.puts "MISS: #{entry[1][:link]}"
        cache[cache_key] = open(entry[1][:link]).read
      end
      
      doc = Hpricot(cache[cache_key])
      
      
      # Make relative images to absolute ones
      (doc/"div[@class='meldung_wrapper'] > p img[@src^='/']").each do |img|
        img['src'] = "http://www.heise.de#{img['src']}"
      end
      
      # Remove ads
      (doc/"div[@class*='ISI_IGNORE']").remove

      # Find all things in a meldung and make them to HTML
      entry[1][:content] = (doc/"div[@class='meldung_wrapper'] > *").to_html
      
      entry[1]
    end
    
    # Cleanup the cache and then write it back
    cache.delete_if do |key, value|
      not current_ids.include? key.to_s[/^\d+/].to_i
    end
    
    File.open(Heisr::CACHE_FILE, 'wb') do |file|
      file.write Marshal.dump(cache)
    end
    
    entries
  end
  
  
  def self.generate_atom updated, entries
    atom = Builder::XmlMarkup.new(:indent => 2)
    atom.instruct!
    
    
    atom.feed :xmlns => 'http://www.w3.org/2005/Atom' do
      atom.title "heise combo News"
      
      atom.link :href => "http://www.heise.de/"

      atom.updated updated
      
      
      atom.author do
        atom.name "heise online"
      end
      
      atom.id "tag:torsten.becker@gmail.com,2008-06:Heisr"
      
      atom.generator 'Heisr', :version => Heisr::RELEASE
      
      
      (entries or []).each do |entry|
        atom.entry do
          # atom.title("#{entry[:source]}: #{entry[:title]}")
          atom.title entry[:title]
          atom.link :href => entry[:link]
          atom.id entry[:id]
          atom.updated entry[:updated]
          atom.category :term => entry[:source]
          
          atom.content entry[:content], :type => 'html'
          
        end
        
      end

    end

    atom.target!
    
  end
  
end
