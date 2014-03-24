Pod::Spec.new do |s|
  s.name     = 'SOXResampler'
  s.version  = '0.9.0'
  s.license  = 'MIT'
  s.summary  = 'An iPhone and OS X libary for resampling PCM audio files'
  s.homepage = 'https://github.com/PRX/SOXResampler'
  s.social_media_url = 'https://twitter.com/prx'
  s.authors  = { 'Chris Kalafarski' => 'chris.kalafarski@prx.org' }
  s.source   = { :git => 'https://github.com/PRX/SOXResampler.git', :tag => "0.9.0", :submodules => true }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
end
