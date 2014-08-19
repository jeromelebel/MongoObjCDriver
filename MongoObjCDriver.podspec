Pod::Spec.new do |s|

  s.name         = "MongoObjCDriver"
  s.version      = "1.0.0"
  s.summary      = "MongoObjCDriver is a framework to connect to a mongodb database"
  s.homepage     = "https://github.com/jeromelebel/MongoObjCDriver"
  s.license      = 'MIT'
  s.author       = "Jerome Lebel"
  s.osx.deployment_target = '10.7'
  s.requires_arc = false
  s.source       = { :git => "https://github.com/jeromelebel/MongoObjCDriver.git", :tag => "v1.0.2" }
  s.source_files = [ "Sources/*.{m,h}", "Libraries/mongo-c-driver/src/mongoc/*.{c,h}", "Libraries/mongo-c-driver/src/libbson/src/bson/*.{c,h}", "Sources/generated-headers/*.h" ]
  s.prepare_command = "git submodule update --init --recursive"
end