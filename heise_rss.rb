%w.time rexml/document ubygems camping builder hpricot open-uri..
each{|_|require _}


Camping.goes :HeiseRSS


module HeiseRSS

  # FEEDS = %w#
  #   http://www.heise.de/security/news/news-atom.xml
  #   http://www.heise.de/newsticker/heise-atom.xml
  # #

  FEEDS = %w#
    newsticker-atom.xml
    security-atom.xml
  #

  
  RELEASE = 1
  

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
      
      @entries = 
      
      # Over all FEEDs
      HeiseRSS::FEEDS.map do |feed|
        doc = REXML::Document.new(open(feed))
        
        # Create a Hash for every feed with "meldung_id => meldung_data_as_hash"
        Hash[
          *doc.elements.collect("/feed/entry") do |entry|
            [ entry.elements['link'].attributes['href'][%r{/meldung/\d+}].to_sym, nil
              # {
              #   :title => entry.elements['title'].text,
              #   :link => entry.elements['link'].attributes['href'],
              #   :id => entry.elements['id'].text,
              #   :updated => entry.elements['updated'].text,
              #   :content => '<b>FOOBAR</b>'
              # }
            ]
          end.flatten
        ]
      end
      # This gives an Array of Hashes containing the entries
      # Now lets eliminate the double entries
      
      
      
      
      puts @entries.inspect
      
      @entries = nil
      
      @updated = Time.now.utc
      
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
    # @headers['Content-Type'] = 'application/atom+xml'
    @headers['Content-Type'] = 'text/plain'
    
    
    atom = Builder::XmlMarkup.new(:indent => 2)
    atom.instruct!
    
    
    atom.fed :xmlns => 'http://www.w3.org/2005/Atom' do
      atom.title "heise online News (++)"
      
      atom.link :href => "http://www.heise.de/"

      atom.updated @updated.xmlschema
      
      
      atom.author do
        atom.name "heise online"
      end
      
      atom.id "tag:pixelshed.net,2008-06-24:HeiseRSS/#{HeiseRSS::RELEASE}"
      
      atom.generator 'HeiseRSS', :version => HeiseRSS::RELEASE
      
      
      (@entries or []).each do |entry|
        atom.entry do
          atom.title entry[:title]
          atom.link :href => entry[:link]
          atom.id entry[:id]
          atom.updated entry[:updated]
          
          atom.content entry[:content], :type => 'html'
          
        end
        
      end

    end

    atom.target!
    
  end
    
end


module HeiseRSS::Helpers
end
