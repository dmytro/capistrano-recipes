
set_default :couchdb_database, "production_db"

before "symlink_database_yml", "create_database_yml"

local_couch = "http://localhost:5984/production_db"

desc ""
task :create_database_yml do
  couchdb_yml = %q{

default: &default
  validation_framework: :active_model # optional
  split_design_documents_per_view: true # optional

development:
  <<: *default
  database: http://localhost:5984/development_db
test:
  <<: *default
  database: http://localhost:5984/test_db

production:
  <<: *default
  database: http://localhost:5984/production_db
}
  
  put couchdb_yml, "#{shared_path}/config/couchdb.yml"
  
end
