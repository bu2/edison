require File.expand_path '../../feature_helper', __FILE__

Given(/^the system knows this (\w+) JSON:$/) do |model, string|
  collection = $db[model.underscore.pluralize]
  object = parse(string)
  object['_id'] = BSON::ObjectId(object['_id'])
  collection.save(object)
end

Given(/^the system knows those (\w+):$/) do |model, table|
  collection = $db[model.underscore.pluralize]
  data = table.hashes
  data.each do |json|
    json['_id'] = BSON::ObjectId(json['_id'])
    collection.save(json)
  end
end

Given(/^the system only knows those (\w+):$/) do |model, table|
  collection = $db[model.underscore.pluralize]
  data = table.hashes
  collection.drop
  data.each do |json|
    json['_id'] = BSON::ObjectId(json['_id'])
    collection.save(json)
  end
end



Then(/^(\w+) with id "(.*?)" should be JSON:$/) do |model, id, expected_json|
  collection = $db[model.underscore.pluralize]
  db_json = collection.find_one( BSON::ObjectId(id) ).to_json
  expect(db_json).to be_json_eql(expected_json)
end
