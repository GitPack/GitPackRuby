Gem::Specification.new do |s|
  s.name        = 'gpack'
  s.version     = '2.0.0'
  s.date        = '2018-02-13'
  s.summary     = "A multiple git repository manager"
  s.description = "Controls cloning and updating of multiple git repositories."
  s.authors     = ["Aaron Cook"]
  s.email       = 'cookacounty@gmail.com'
  s.files       = ["lib/gpack.rb"]
  s.homepage    =
    'https://github.com/GitPack/GitPackRuby'
  s.license       = 'GPL-3.0'
  s.executables << 'gpack'
end


gem "gpack", :git => "git@github.com:GitPack/GitPackRuby.git"
