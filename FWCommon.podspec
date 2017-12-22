#
#  Be sure to run `pod spec lint FWCommon.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "FWCommon"
  s.version      = "1.0.1"
  s.summary      = "FWCommon contains many libs  for  developers"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
  This description is used to generate tags and improve search results.FWCommon contains many libs  for  developers
                   DESC

  s.homepage     = "https://github.com/FSilver/FWCommon"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = { :type => "Proprietary", :text => "Copyright 2017 FSilver Co., Ltd. All rights reserved.\n" }
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "fangwei" => "740987339@qq.com" }
  # Or just: s.author    = "fangwei"
  # s.authors            = { "fangwei" => "740987339@qq.com" }
  # s.social_media_url   = "http://twitter.com/fangwei"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  s.platform     = :ios
  # s.platform     = :ios, "5.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/FSilver/FWCommon.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.subspec 'FWCommon' do |cache|
    cache.source_files = "FWCommon/Lib/FWCache/*.{h,m}" #子源的源文件地址
    cache.frameworks = 'UIKit'
  end
  s.subspec 'FWCommon' do |carouselView|
    carouselView.source_files = "FWCommon/Lib/FWCarouselView/*.{h,m}" #子源的源文件地址
    carouselView.frameworks = 'UIKit'
  end
  s.subspec 'FWCommon' do |drawView|
    drawView.source_files = "FWCommon/Lib/FWDrawView/*.{h,m}" #子源的源文件地址
    drawView.frameworks = 'UIKit'
  end
  s.subspec 'FWCommon' do |monitor|
    monitor.source_files = "FWCommon/Lib/FWMonitor/*.{h,m}" #子源的源文件地址
    monitor.frameworks = 'UIKit'
  end
  s.subspec 'FWCommon' do |progressHUD|
    progressHUD.source_files = "FWCommon/Lib/FWProgressHUD/*.{h,m}" #子源的源文件地址
    progressHUD.frameworks = 'UIKit'
  end
  s.subspec 'FWCommon' do |segment|
    segment.source_files = "FWCommon/Lib/FWSegment/*.{h,m}" #子源的源文件地址
    segment.frameworks = 'UIKit'
  end




  #s.source_files  = "FWCommon/Lib/**/*.{h,m}"

  #s.exclude_files = "FWCommon/Lib"

  #s.public_header_files = "FWCommon/Lib/**"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  s.framework  = "UIKit"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
