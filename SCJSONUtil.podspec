#
#  Be sure to run `pod spec lint SCJSONUtil.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SCJSONUtil"
  s.version      = "2.5.5"
  s.summary      = "轻量、方便的 JSON 转 Model 框架，支持 iOS 和 OS X 平台"

  s.description  = <<-DESC
                   轻量、方便的 JSON 转 Model 框架；服役搜狐的SDK和搜狐影音 Mac 版！
                   DESC

  s.homepage = "https://debugly.cn/SCJSONUtil"
  s.license  = "Apache License"
  s.author   = { "qianlongxu" => "qianlongxu@gmail.com" }

  s.ios.deployment_target = "5.0"
  s.osx.deployment_target = "10.6"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source   = { :git => "https://github.com/debugly/SCJSONUtil.git", :tag => "#{s.version}" }
  s.source_files = "SCJSONUtil/**/*.{h,m,c}"
  s.private_header_files = "SCJSONUtil/internal/*.h"
  s.framework = "Foundation"
  s.requires_arc = true

end
