Pod::Spec.new do |s|
  s.name         = 'ObjectiveDDP'
  s.version      = '0.0.1'
  s.license      = 'MIT'
  s.summary      = 'Facilitates communication between iOS clients and meteor.js servers'
  s.homepage     = 'https://github.com/TBD'
  s.author       = 'Jesse Bounds'
  s.source       = { :git => 'git://github.com/boundsj/TBD.git', :tag => 'v0.0.1' }
  s.source_files = 'lib/*'
  s.requires_arc = true
  s.dependency 'SocketRocket', :git => "git@github.com:square/SocketRocket.git"
end
