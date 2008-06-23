%w*ubygems camping*.each{|_|require _}


Camping.goes :HeiseRSS


module HeiseRSS

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
    
  end
    
end


module HeiseRSS::Helpers
end


# def HeiseRSS.create
# end
