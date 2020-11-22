Pod::Spec.new do |s|
  s.name         = "CodableCSV"
  s.version      = "0.6.4"
  s.summary      = "Read and write CSV files row-by-row or through Swift's Codable interface."
  s.description  = <<-DESC
    CodableCSV offers imperative and declarative ways to read and write CSV files. It is extensively configurable and is capable of reading multiple types of entries and write to many outputs.
    DESC
  s.homepage     = "https://github.com/dehesa/CodableCSV"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Marcos Sánchez-Dehesa Carballo" => "san.dehesa@gmail.com" }
  s.social_media_url          = "https://twitter.com/san_dehesa"
  s.ios.deployment_target     = "8.0"
  s.osx.deployment_target     = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target    = "9.0"
  s.swift_version             = ["5.1", "5.2", "5.3"]
  s.source       = { :git => "https://github.com/dehesa/CodableCSV.git", :tag => "#{s.version}" }
  s.source_files = "sources", "sources/**/*.swift"

end
