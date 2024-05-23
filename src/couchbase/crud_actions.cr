module CrudActions
  extend self

  def insert(collection_name, values)
    CouchbaseQuery.new(statement: "INSERT INTO #{collection_name} (KEY, VALUE) VALUES (UUID(), #{values.to_json}) RETURNING META().id as id, #{collection_name} as document;")
  end

  def update_by_id(collection_name, id, values)
    statement = "UPDATE #{collection_name} USE KEYS \"#{id}\" SET "
    values.each do |key, value|
      statement += "#{key} = \"#{value}\", "
    end
    statement = statement.chomp(", ") + " RETURNING META().id as id, #{collection_name} as document;"
    
    CouchbaseQuery.new(statement: statement, args: JSON.parse(values.values.to_json))
  end

  def update_where(collection_name, values, conditions)
    statement = "UPDATE #{collection_name} SET "
    values.each do |key, value|
      statement += "#{key} = \"#{value}\", "
    end
    statement = statement.chomp(", ")
    
    where_clause = conditions.map do |k, _|
      "#{k} =?"
    end.join(" AND ")
    
    statement += " WHERE #{where_clause} RETURNING META().id as id, #{collection_name} as document;"
    
    CouchbaseQuery.new(statement: statement, args: conditions.values.to_a)
  end

  def delete_by_id(collection_name, id)
    statement = "DELETE FROM #{collection_name} USE KEYS \"#{id}\" RETURNING META().id as id, #{collection_name} as document;"
    CouchbaseQuery.new(statement)
  end

  def delete_where(collection_name, conditions)
    statement = "DELETE FROM #{collection_name} "

    where_clause = conditions.map do |k, _|
      "#{k} =?"
    end.join(" AND ")
    
    statement += " WHERE #{where_clause} RETURNING META().id as id, #{collection_name} as document;"

    CouchbaseQuery.new(statement: statement, args: JSON.parse(conditions.values.to_json))
  end

  def select_by_id(collection_name, id, fields : Array(String) = ["*"])
    select_string = ""
    fields.each do |v|
      select_string += " #{v} "
    end
    CouchbaseQuery.new "SELECT META().id AS id, #{select_string} FROM #{collection_name} document USE KEYS \"#{id}\";"
  end

  def select_by(collection_name, conditions, fields : Array(String) = ["*"])
    select_string = ""

    fields.each do |v|
      select_string += " #{v} "
    end

    where_clause = conditions.map do |k, _|
      "#{k} = ?"
    end.join(" AND ")

    statement = "SELECT META().id AS id, #{select_string} FROM #{collection_name} document WHERE #{where_clause};"

    CouchbaseQuery.new(statement: statement, args: JSON.parse(conditions.values.to_json))
  end

  def select(collection_name, statement, args, fields : Array(String) = ["*"])
    select_string = ""

    fields.each do |v|
      select_string += " #{v} "
    end

    statement = "SELECT META().id AS id, #{select_string} FROM #{collection_name} document WHERE #{statement};"

    CouchbaseQuery.new(statement: statement, args: JSON.parse(conditions.values.to_json))
  end
end