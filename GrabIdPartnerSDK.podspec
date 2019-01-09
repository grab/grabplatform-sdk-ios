#
# Be sure to run `pod lib lint GrabIdPartnerSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
# Copyright (c) 2018 GrabTaxi Pte Ltd.

Pod::Spec.new do |s|
  s.name             = 'GrabIdPartnerSDK'
  s.version          = '1.0.0'
  s.summary          = 'GrabIdPartner SDK for OAuth2.0 support.'
  s.description      = 'The GrabIdPartner SDK allows users to sign in with their Grab account from third-party apps.'
  s.homepage         = 'https://github.com/grab/grabplatform-sdk-ios'
  s.swift_version    = '4.0'
  s.license          = { :type => 'Copyright', :text => 'Copyright (c) 2018 GrabTaxi Pte Ltd.', :file => 'LICENSE' }
  s.author           = { 'GrabTaxi Pte Ltd.' => 'http://grab.com' }
  s.source           = { :git => 'https://github.com/grab/grabplatform-sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'GrabIdPartnerSDK/Classes/**/*'  
end
