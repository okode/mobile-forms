Pod::Spec.new do |s|
  s.name             = 'MobileForms'
  s.version          = '0.0.1'
  s.summary          = 'A multiplatform dynamic Web forms generator for mobile apps'
  s.description      = <<-DESC
                        MobileForms allows creating forms dynamically by using a form definition in JSON format. All
                        generated forms has definable fields with all its attributes and validation rules embeded in the
                        same definition file and supports receiving callbacks in native code for different event types as
                        focus, change or submitting form generating a JSON response with the model defined in the form.
                       DESC
  s.homepage         = 'http://www.okode.com'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.authors          = { 'Okode' => 'info@okode.com' }
  s.platform         = :ios, "8.0"
  s.source           = { :git => 'https://github.com/okode/mobileforms.git', :tag => s.version.to_s }
  s.source_files     = 'ios/MobileForms/*.swift'
  s.resource_bundles = { 'MobileForms' => ['assets/mobileforms'] }
  s.requires_arc     = true
end
