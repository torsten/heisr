%w.time rexml/document ubygems camping builder hpricot open-uri..
each{|_|require _}


Camping.goes :HeiseRSS


module HeiseRSS

  FEEDS = %w#
    http://www.heise.de/newsticker/heise-atom.xml
    http://www.heise.de/security/news/news-atom.xml
  #

  # FEEDS = %w#
  #   newsticker-atom.xml
  #   security-atom.xml
  # #

  
  RELEASE = 2
  
  CACHE_FILE = 'heise_cache.marshald'
  
  

  def r500(k,m,x)
    env = @env
    r(500, Mab.new { 
      h1 '#500'
      dl do
        dt do
          strong x.class.to_s
          text " from #{k}.#{m}:"
        end
        dd x.message
      end

      # produce some nice, clickable error output
      if env.REMOTE_ADDR == '127.0.0.1'
        ul do x.backtrace.each do |bt|
          li do
            a bt, :href =>
              bt.gsub(/^(.+):(\d+).*$/, 'txmt://open/?line=\2&url=file://\1')
          end unless bt =~ %r{^\(eval\):|lib/mongrel|lib/markaby}
        end end
      else
        # TODO: handle this somehow by sending mails or something
        text "Please mail me a screenshot of this."
      end
    }.to_s)
  end

  def r404(p)
    r(404, Mab.new { h1 "#404"; text "#{p.gsub('<', '&lt;')} not found"})
  end
  
end


module HeiseRSS::Controllers
  
  class Index < R '/'
    def get
      render :index
    end
  end
  
  class Feed < R '/feed.atom'
    def get
      
      cache = Marshal.load(File.read(CACHE_FILE)) rescue {}
      
      @entries = 
      
      # Over all FEEDs
      HeiseRSS::FEEDS.map do |feed|
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
                :content => '<b>FOOBAR</b>'
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
        cache_key = "#{entry[0]}#{entry[1][:updated]}".to_sym
        
        if not cache[cache_key]
          puts "MISS: #{entry[1][:link]}"
          cache[cache_key] = open(entry[1][:link]).read
        end
        
        doc = Hpricot(cache[cache_key])
        
        
        # Make relative images to absolute ones
        (doc/"div[@class='meldung_wrapper'] > p img[@src^='/']").each do |img|
          img['src'] = "http://www.heise.de#{img['src']}"
        end
        
        # Remove ads
        (doc/"div[@class='ISI_IGNORE']").remove

        # Find all things in a meldung and make them to HTML
        entry[1][:content] = (doc/"div[@class='meldung_wrapper'] > *").to_html
        
        entry[1]
      end
      
      
      File.open(CACHE_FILE, 'wb') do |file|
        file.write Marshal.dump(cache)
      end
      
      
      @updated = Time.now.utc.xmlschema
      
      render :_atom
    end
  end
  
end


module HeiseRSS::Views
  
  def index
    h1 "HeiseRSS++"
    
    p do
      text "The "
      a "heise.de", :href => 'http://heise.de/'
      text " RSS feeds combined and with real text in them. "
      a "Check it out", :href => R(Feed)
      text '.'
    end
    
  end
  
  def _atom
    @headers['Content-Type'] = 'application/atom+xml'
    # @headers['Content-Type'] = 'text/plain'
    
    
    atom = Builder::XmlMarkup.new(:indent => 2)
    atom.instruct!
    
    
    atom.feed :xmlns => 'http://www.w3.org/2005/Atom' do
      atom.title "heise online News (++)"
      
      atom.link :href => "http://www.heise.de/"

      atom.updated @updated
      
      
      atom.author do
        atom.name "heise online"
      end
      
      atom.id "tag:torsten.becker@gmail.com,2008-06:HeiseRSS++"
      
      atom.generator 'HeiseRSS', :version => HeiseRSS::RELEASE
      
      
      (@entries or []).each do |entry|
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


module HeiseRSS::Helpers
end
