Pod::Spec.new do |s|
  s.name         = "JDDropbox"
  s.version      = "0.0.3"
  s.summary      = "JDDropbox"
  s.description  = <<-DESC
    JDDropbox
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
  s.source       = { :git => "https://github.com/johannesd/JDDropbox.git" }
  s.platform     = :ios, '5.0'
  s.source_files  = '*.{h,m}'

  s.exclude_files = 'Classes/Exclude'
  s.requires_arc = true

  s.dependency 'ObjectiveDropboxOfficial'
  s.dependency 'Reachability'
  s.dependency 'BlocksKit'
  s.dependency 'JDCategories'

end
