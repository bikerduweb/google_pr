# PagerankChecker

# (C) 2006-2007 under terms of LGPL v2.1
# by Vsevolod S. Balashov <vsevolod@balashov.name>
# based on 3rd party code snippets (see comments)
#
# transformed as a rails plugin by Olivier Ruffin (http://www.veilleperso.com)
#

require 'uri'
require 'open-uri'

# http://blog.outer-court.com/archive/2004_06_27_index.html#108834386239051706
class AutomatedQueryError < StandardError; end;

class GooglePR

  M=0x100000000 # modulo for unsigned int 32bit(4byte)
  attr_accessor :uri

  # Create a new GooglePR object with the given 'uri' parameter
  def initialize(uri)
    # TODO should raise a URI::InvalidURIError with a invalid URI parameter
    @uri = uri
  end

  def m1(a,b,c,d)
    (((a+(M-b)+(M-c))%M)^(d%M))%M # mix/power mod
  end

  def i2c(i)
    [i&0xff, i>>8&0xff, i>>16&0xff, i>>24&0xff]
  end

  def c2i(s,k=0)
    ((s[k+3].to_i*0x100+s[k+2].to_i)*0x100+s[k+1].to_i)*0x100+s[k].to_i
  end

  def mix(a,b,c)
    a = a%M; b = b%M; c = c%M
    a = m1(a,b,c, c >> 13); b = m1(b,c,a, a <<  8); c = m1(c,a,b, b >> 13)
    a = m1(a,b,c, c >> 12); b = m1(b,c,a, a << 16); c = m1(c,a,b, b >>  5)
    a = m1(a,b,c, c >>  3); b = m1(b,c,a, a << 10); c = m1(c,a,b, b >> 15)
    [a, b, c]
  end

  def old_cn(iurl = 'info:' + @uri)
    a = 0x9E3779B9; b = 0x9E3779B9; c = 0xE6359A60
    len = iurl.size
    k = 0
    while (len >= k + 12) do
      a += c2i(iurl,k); b += c2i(iurl,k+4); c += c2i(iurl,k+8)
      a, b, c = mix(a, b, c)
      k = k + 12
    end
    a += c2i(iurl,k); b += c2i(iurl,k+4); c += (c2i(iurl,k+8) << 8) + len
    a,b,c = mix(a,b,c)
    return c
  end
  
  # Calculates de checksum to use as 'ch' parameter on request_uri, 
  # for example the checksum of www.rubyonrails.com is 6602033163
  def cn
    ch = old_cn
    ch = ((ch/7) << 2) | ((ch-(ch/13).floor*13)&7)
    new_url = []
    20.times { i2c(ch).each { |i| new_url << i }; ch -= 9 }
    ('6' + old_cn(new_url).to_s).to_i
  end

  # URI that gets the pagerank, 
  # for example to get the Google's pagerank of www.rubyonrails.com the request_uri is http://toolbarqueries.google.com/search?client=navclient-auto&hl=en&ch=6602033163&ie=UTF-8&oe=UTF-8&features=Rank&q=info:www.rubyonrails.com
  def request_uri
    # http://www.bigbold.com/snippets/posts/show/1260 + _ -> %5F
    "http://toolbarqueries.google.com/search?client=navclient-auto&hl=en&ch=#{cn}&ie=UTF-8&oe=UTF-8&features=Rank&q=info:#{URI.escape(@uri, /[^-.!~*'()a-zA-Z\d]/)}"
  end

  # Return a number between 0 to 10, that represents the Google PageRank
  def page_rank(uri = @uri)
    @uri = uri if uri != @uri
    res = HTTParty.get(request_uri, :headers => {"User-Agent" => Object.const_defined?("WITH_USER_AGENT") ? Object.const_get("WITH_USER_AGENT") : "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; fr; rv:1.9.0.10) Gecko/2009042315 Firefox/3.0.10" })
    if (m=res.to_s.match(/Rank_1:\d:(\d+)/))
      return m[1].to_i
    elsif res.to_s.match(/automated queries/im)
      raise AutomatedQueryError.new("Blacklisted for automated queries")
    end
  rescue OpenURI::HTTPError, SocketError
    nil
  end

  private :m1, :i2c, :c2i, :mix, :old_cn
end
