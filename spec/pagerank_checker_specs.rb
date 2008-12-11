require File.join(File.dirname(__FILE__), '/../lib/google_pr')

describe GooglePR do
  
  describe "with no uri parameter" do
    it "should complain" do 
      lambda { GooglePR.new }.should raise_error(ArgumentError)
    end
  end
  
  describe "with a incorrect uri parameter" do
    it "should complain" do
      # TODO it should raise a error, but it's not
      # maybe will be necessary change some logic to raise a error when a invalid URI is used
      lambda { GooglePR.new("It's not a valid uri!!!!") }.should raise_error(URI::InvalidURIError)
    end
  end
  
  describe "with a correct uri" do
    before(:each) do
      @pr = GooglePR.new("www.rubyonrails.com")
    end
    it "should return a GooglePR object" do
      @pr.is_a? GooglePR
    end
    it "should return a correct checksum" do 
      @pr.cn.should == 6602033163
    end
    it "should return a correct request uri" do
      @pr.request_uri.should == "http://toolbarqueries.google.com/search?client=navclient-auto&hl=en&ch=6602033163&ie=UTF-8&oe=UTF-8&features=Rank&q=info:www.rubyonrails.com"
    end
    it "should return a valid Google's pagerank number between 0 and 10" do
      @pr.page_rank.should >= 0 and @pr.page_rank.should <= 10
    end
  end
  
end

