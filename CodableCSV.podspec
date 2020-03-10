Pod::Spec.new do |s|
  s.name             = 'CodableCSV'
  s.version          = '0.4.0'
  s.summary          = "Read and write CSV files row-by-row or through Swift's Codable interface."

  s.homepage         = 'https://github.com/dehesa/CodableCSV'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Marcos Sánchez-Dehesa' => 'san.dehesa@gmail.com' }
  s.source           = { :git => 'https://github.com/dehesa/CodableCSV.git', :tag => s.version.to_s }

  s.swift_version = '5.1'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '5.0'

  s.source_files = 'Sources/**/*'
end
