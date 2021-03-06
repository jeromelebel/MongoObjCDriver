Pod::Spec.new do |s|

  s.name         = "MongoObjCDriver"
  s.version      = "1.0.6"
  s.summary      = "MongoObjCDriver is a framework to connect to a mongodb database with async API. This framework is used by https://github.com/jeromelebel/MongoHub-Mac"
  s.homepage     = "https://github.com/jeromelebel/MongoObjCDriver"
  s.license      = { :type => "-", :file => "README" }
  s.author       = "Jerome Lebel"
  s.osx.deployment_target = '10.7'
  s.requires_arc = false
  s.source       = { :git => "https://github.com/jeromelebel/MongoObjCDriver.git", :tag => "1.0.6" }
  s.source_files = [ "Sources/*.{m,h}", "Libraries/mongo-c-driver/src/mongoc/*.{c,h}", "Libraries/mongo-c-driver/src/libbson/src/bson/*.{c,h}", "Sources/generated-headers/*.h", "Libraries/mongo-c-driver/src/libbson/src/*.{c,h}", "Libraries/mongo-c-driver/src/libbson/src/yajl/*.{c,h}" ]
  s.resource     = [ "Libraries/mongo-c-driver/src/mongoc/*.{defs,def}" ]
  s.prepare_command = "git submodule update --init --recursive"
  s.compiler_flags = "-DBSON_COMPILATION -DMONGOC_COMPILATION"
  s.header_mappings_dir = "Libraries/mongo-c-driver/src/libbson/src/"
end