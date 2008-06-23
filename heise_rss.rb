%w*ubygems camping builder*.each{|_|require _}


Camping.goes :HeiseRSS


module HeiseRSS

  FEEDS = %w#
    http://www.heise.de/security/news/news-atom.xml
    http://www.heise.de/newsticker/heise-atom.xml
  #

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
    atom = Builder::XmlMarkup.new(:indent => 2)
    atom.instruct!
    
    
    atom.feed :xmlns => 'http://www.w3.org/2005/Atom' do
      atom.title Stunts::TITLE
      
      atom.author do
        atom.name Stunts::AUTHOR
      end
      atom.rights "Copyright #{Time.now.year} #{Stunts::AUTHOR}"
      
      atom.link :rel => 'alternate', :type => 'text/html',
        :href => Stunts::BASE_URL
      
      atom.link :rel => 'self', :type => 'application/atom+xml',
        :href => "#{Stunts::BASE_URL}posts.atom"
      
      atom.generator 'Stunts', :version => Stunts::RELEASE.gsub(%r{.+/}, '')
      
      atom.id "#{Stunts::BASE_URL}posts.atom"
      
      atom.updated(
        if not @posts.nil? and @posts.any?
          @posts.first[:created_at].xmlschema
        else
          Time.now.utc.xmlschema
        end
      )
      
      (@posts or []).each do |post|
        
        content = if post[:text] =~ /^\s*<p>/m
          post[:text]
        else
          flowztext(post[:text])
        end
        
        unique_link = "#{Stunts::BASE_URL}#{post[:_id]}"
        
        
        atom.entry do
          atom.id unique_link
          atom.updated post[:created_at].xmlschema
          
          atom.link :rel => 'alternate', :type => 'text/html',
            :href => unique_link
          
          atom.title post[:title]
          
          atom.content content, :type => 'html'
        end
        
      end

    end

    atom.target!
    
  end
    
end


module HeiseRSS::Helpers
end
