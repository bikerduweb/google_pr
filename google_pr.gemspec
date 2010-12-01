$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

include_files = ["README*", "Rakefile", "init.rb", "{lib,tasks,test,rails,generators,shoulda_macros}/**/*"].map do |glob|
  Dir[glob]
end.flatten

Gem::Specification.new do |s|
  s.name              = "google_pr"
  s.version           = '1.0.0'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.author            = "Vsevolod S. Balashov"
  s.email             = "vsevolod@balashov.name"
  s.summary           = "Google PR check"
  s.description       = "Check Google Pagerank"
  s.homepage          = ""
  s.has_rdoc          = false
  s.files             = include_files
  s.require_path      = "lib"
end
