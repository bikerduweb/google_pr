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
class AutomatedQueryError < StandardError
end



# extracted from PageRankr
# cf. https://github.com/blatyo/page_rankr
# use: Google::Pagerank.new(domain).check

class GoogleChecksum
  class << self
    def generate(site)
      bytes  = byte_array(site)
      length = bytes.length
      a = b = 0x9E3779B9
      c = 0xE6359A60

      k, len = 0, length
      while(len >= 12)
        a, b, c = mix(*shift(a, b, c, k, bytes))
        k += 12
        len -= 12
      end

      c = c + length

      c = mix(*toss(a, b, c, bytes, len, k))[2]
      "6" + c.to_s
    end

    private

    def byte_array(site)
      bytes = []
      site.each_byte {|b| bytes << b}
      bytes
    end

    # Need to keep numbers in the unsigned int 32 range
    def m(v)
      v % 0x100000000
    end

    def shift(a, b, c, k, bytes)
      a = m(a + bytes[k + 0] + (bytes[k + 1] << 8) + (bytes[k +  2] << 16) + (bytes[k +  3] << 24))
      b = m(b + bytes[k + 4] + (bytes[k + 5] << 8) + (bytes[k +  6] << 16) + (bytes[k +  7] << 24))
      c = m(c + bytes[k + 8] + (bytes[k + 9] << 8) + (bytes[k + 10] << 16) + (bytes[k + 11] << 24))

      [a, b, c]
    end

    def mix(a, b, c)
      a, b, c = m(a), m(b), m(c)

      a = m(a-b-c) ^ m(c >> 13)
      b = m(b-c-a) ^ m(a << 8)
      c = m(c-a-b) ^ m(b >> 13)

      a = m(a-b-c) ^ m(c >> 12)
      b = m(b-c-a) ^ m(a << 16)
      c = m(c-a-b) ^ m(b >> 5)

      a = m(a-b-c) ^ m(c >> 3)
      b = m(b-c-a) ^ m(a << 10)
      c = m(c-a-b) ^ m(b >> 15)

      [a, b, c]
    end

    def toss(a, b, c, bytes, len, k)
      case len
      when 9..11
        c = c + (bytes[k+len-1] << ((len % 8) * 8))
      when 5..8
        b = b + (bytes[k+len-1] << ((len % 5) * 8))
      when 1..4
        a = a + (bytes[k+len-1] << ((len - 1) * 8))
      else
        return [a, b, c]
      end
      toss(a, b, c, bytes, len-1, k)
    end
  end
end

class GooglePR
  attr_accessor :domain, :checksum

  def initialize(domain)
    self.domain = domain
    self.checksum = GoogleChecksum.generate("info:#{self.domain}")
  end

  # Return a number between 0 to 10, that represents the Google PageRank
  def check
    url = "#{toolbar_url}?" + params.collect {|k,v| "#{k}=#{v}"}.join("&")
    res = HTTParty.get(url, :headers => {"User-Agent" => "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)" }, :format => :raw)
    res.to_s.match(/Rank_\d+:\d+:(\d+)/) ? $1.to_i : nil
  end

  private
  def toolbar_url
    "http://toolbarqueries.google.com/tbr"
  end

  def params
    {:client => "navclient-auto", :ch => @checksum, :features => "Rank", :q => "info:#{self.domain}"}
  end
end
