Pod::Spec.new do |s|

  s.name         = "MongoObjCDriver"
  s.version      = "1.0.0"
  s.summary      = "MongoObjCDriver is a framework to connect to a mongodb database"
  s.homepage     = "https://github.com/jeromelebel/MongoObjCDriver"
  s.license      = 'MIT'
  s.author       = "Jerome Lebel"
  s.osx.deployment_target = '10.7'
  s.source       = { :git => "https://github.com/jeromelebel/MongoObjCDriver.git", :tag => "v1.0" }
end