Pod::Spec.new do |s|
  s.name             = 'CodableCSV'
  s.version          = '0.2.0'
  s.summary          = "Read and write CSV files row-by-row or through Swift's Codable interface."

  s.homepage         = 'https://github.com/dehesa/CodableCSV'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dehesa' => 'san.dehesa@gmail.com' }
  s.source           = { :git => 'https://github.com/dehesa/CodableCSV.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.source_files = 'Souces/**/*'
end
