Pod::Spec.new do |s|
  s.name         = "JDDropbox"
  s.version      = "0.0.1"
  s.summary      = "JDDropbox"
  s.description  = <<-DESC
                   DESC
  s.homepage     = "https://github.com/johannesd/JDDropbox.git"
  s.license      = { 
    :type => 'Custom permissive license',
    :text => <<-LICENSE
          Free for commercial use and redistribution. No warranty.

        	Johannes Dörr
        	mail@johannesdoerr.de
    LICENSE
  }
  s.author       = { "Johannes Doerr" => "mail@johannesdoerr.de" }
  s.platform     = :ios, '5.0'
  s.source_files  = '*.{h,m}'

  s.exclude_files = 'Classes/Exclude'
  s.requires_arc = true

  s.frameworks = 'Dropbox'
  s.dependency 'Dropbox-Sync-API-SDK'
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '"${PODS_ROOT}/Dropbox-Sync-API-SDK/dropbox-ios-sync-sdk-3.1.2"' }  

end
