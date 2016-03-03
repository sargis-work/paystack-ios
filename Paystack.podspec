Pod::Spec.new do |s|
  s.name                           = 'Paystack'
  s.version                        = '1.0.0'
  s.summary                        = 'Paystack is a web-based API helping African Businesses accept payments online.'
  s.description                    = <<-DESC
   Paystack makes it easy for African Businesses to accept Mastercard, Visa and Verve cards from anyone, anywhere in the world. 
   
   This is the Paystack SDK for iOS. Collect Card details on iOS and get a token. Shoulders the burden of PCI compliance by helping you avoid the need to send card data directly to your server. Instead you send to Paystack's server and get a token which you can charge later in your server-side code.
  DESC
  
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://paystack.com'
  s.authors                        = { 'Ibrahim Lawal' => 'ibrahim@paystack.com', 'Paystack' => 'support@paystack.com' }
  s.source                         = { :git => 'https://github.com/paystackhq/paystack-ios.git', :tag => "v#{s.version}" }
  s.ios.frameworks                 = 'Foundation', 'Security'
  s.ios.weak_frameworks            = 'PassKit', 'AddressBook'
  s.osx.frameworks                 = 'Foundation', 'Security', 'WebKit'
  s.requires_arc                   = true
  s.ios.deployment_target          = '7.0'
  s.osx.deployment_target          = '10.9'
  s.default_subspecs               = 'Core'

  s.subspec 'Core' do |ss|
    ss.public_header_files         = 'Paystack/PublicHeaders/*.h'
    ss.ios.public_header_files     = 'Paystack/PublicHeaders/UI/*.h'
    ss.source_files                = 'Paystack/PublicHeaders/*.h', 'Paystack/RSA/*.{h,m}', 'Paystack/*.{h,m}'
    ss.ios.source_files            = 'Paystack/PublicHeaders/UI/*.h', 'Paystack/UI/*.{h,m}', 'Paystack/Fabric/*'
    ss.resources                   = 'Paystack/Resources/**/*'
  end

end
