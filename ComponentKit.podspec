Pod::Spec.new do |s|
  s.name = "ComponentKit"
  s.version = "0.13.1"
  s.summary = "A React-inspired view framework for iOS with custom changes built by zoog. Forked from facebook/componentkit"
  s.homepage = "https://componentkit.org"
  s.authors = 'adamjernst@fb.com'
  s.license = 'BSD'
  s.source = {
    :git => "https://github.com/facebook/ComponentKit.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/componentkit'
  s.platform = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'ComponentKit/**/*', 'ComponentTextKit/**/*'
  s.frameworks = 'UIKit', 'CoreText'
  s.library = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }

  s.subspec 'FLAnimatedImage' do |animated|
    animated.source_files = "FLAnimatedImage/**/*.{h,m}"
    animated.frameworks = "QuartzCore", "ImageIO", "MobileCoreServices", "CoreGraphics"
    animated.requires_arc = true
    animated.dependency 'FLAnimatedImage'
  end
end

