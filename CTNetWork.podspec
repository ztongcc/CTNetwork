Pod::Spec.new do |s|


  s.name         = "CTNetWork"
  s.version      = "1.0"
s.summary      = "CTNetWork is a net request util based on AFNetworking, base on NSURLSessionTask"
  s.homepage     = "https://github.com/Excalibur-CT/CTNetWork.git"
  s.license      = "MIT"
  s.author       =  "chengzhitong email:763761676@qq.com"

  s.source        = { :git => "https://github.com/Excalibur-CT/CTNetWork.git", :tag => s.version.to_s }
  s.source_files  = "CTNetWork/*.{h,m}"
  s.platform      = :ios, '7.0'
  s.requires_arc  = true
  s.frameworks    = 'UIKit'
  s.dependency 'AFNetworking', '~> 3.0.2'

end
