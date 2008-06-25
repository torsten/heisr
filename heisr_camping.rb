%w.heisr_core ubygems camping..each{|_|require _}


Camping.goes :HeisrCamping


module HeisrCamping

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

end


module HeisrCamping::Controllers
  
  class Index < R '/'
    def get
      render :index
    end
  end
  
  class Feed < R '/feed.atom'
    def get
      @entries = Heisr.fetch_entries
      @updated = Time.now.utc.xmlschema
      
      render :_atom
    end
  end
  
end


module HeisrCamping::Views
  
  def index
    h1 "Heisr"
    
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
    
    Heisr.generate_atom @updated, @entries
  end
    
end
