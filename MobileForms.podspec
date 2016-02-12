Pod::Spec.new do |s|
  s.name                = 'MobileForms'
  s.version             = '1.0'
  s.summary             = 'Dynamic Web Forms for Mobile Apps'
  s.homepage            = 'http://www.okode.com'
  s.license             = 'Apache License, Version 2.0'
  s.authors             = 'Okode'
  s.source              = { :git => 'https://github.com/okode/mobileforms.git' }
  s.source_files        = 'ios/MobileForms/*.{h,m}'
#  s.resources           = 'assets/mobileforms'
  s.requires_arc        = true
end
