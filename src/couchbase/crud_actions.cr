module CrudActions
  extend self

  def all(collection_name, fields : Array(String) = ["*"])
    select_string = ""

    fields.each do |v|
      if v == "*"
        select_string += " #{collection_name}.#{v} "
      else
        select_string += " #{collection_name}.`#{v}` "
      end
    end
    
    CouchbaseQuery.new(statement: "SELECT META().id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name};")
  end

  def insert(collection_name, values)
    CouchbaseQuery.new(statement: "INSERT INTO #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} (KEY, VALUE) VALUES (UUID(), #{values.to_json}) RETURNING META().id, #{collection_name}.*;")
  end

  def update_by_id(collection_name, id, values)
    statement = "UPDATE #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} USE KEYS \"#{id}\" SET "
    values.each do |key, value|
      next if key.to_s == "id"
      if value.is_a?(Int)
        statement += "`#{key}` = #{value}, "
      else
        statement += "`#{key}` = \"#{value}\", "
      end
    end
    statement = statement.chomp(", ") + " RETURNING META().id, #{collection_name}.*;"
    
    CouchbaseQuery.new(statement: statement, args: JSON.parse(values.values.to_json))
  end

  def update_where(collection_name, values, conditions)
    statement = "UPDATE #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name}.#{collection_name} SET "

    values.each do |key, value|
      next if key.to_s == "id"
      if value.is_a?(Int)
        statement += "`#{key}` = #{value}, "
      else
        statement += "`#{key}` = \"#{value}\", "
      end
    end
    statement = statement.chomp(", ")
    
    where_clause = conditions.map do |k, v|
      key = k.to_s == "id" ? "META(t).id" : "`#{k}`"
      if v.is_a?(Array)
        "#{key} in ?"
      else
        "#{key} = ?"
      end
    end.join(" AND ")
    
    statement += " WHERE #{where_clause} RETURNING META().id as id, #{collection_name} as document;"
    
    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values))
  end

  def delete_by_id(collection_name, id)
    statement = "DELETE FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} USE KEYS \"#{id}\" RETURNING META().id, #{collection_name}.*;"
    CouchbaseQuery.new(statement)
  end

  def delete_where(collection_name, conditions)
    statement = "DELETE FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} "

    where_clause = conditions.map do |k, v|
      key = k.to_s == "id" ? "META(t).id" : "`#{k}`"
      if v.is_a?(Array)
        "`#{key}` in ?"
      else
        "`#{key}` = ?"
      end
    end.join(" AND ")
    
    statement += " WHERE #{where_clause} RETURNING META().id, #{collection_name};"

    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values))
  end

  def select_by_id(collection_name, id, fields : Array(String) = ["*"])
    select_string = ""

    fields.each do |v|
      if v == "*"
        select_string += " #{collection_name}.#{v} "
      else
        select_string += " #{collection_name}.`#{v}` "
      end
    end

    CouchbaseQuery.new "SELECT META().id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} USE KEYS \"#{id}\";"
  end

  def select_by(collection_name, conditions, fields : Array(String) = ["*"])
    select_string = ""

    fields.each do |v|
      if v == "*"
        select_string += " #{collection_name}.#{v} "
      else
        select_string += " #{collection_name}.`#{v}` "
      end
    end

    where_clause = conditions.map do |k, v|
      key = k.to_s == "id" ? "META(t).id" : "`#{k}`"
      if v.is_a?(Array)
        "`#{key}` in ?"
      else
        "`#{key}` = ?"
      end
    end.join(" AND ")

    statement = "SELECT META().id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} WHERE #{where_clause};"

    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values))
  end

  def select(collection_name, statement, args, fields : Array(String) = ["*"])
    select_string = ""

    fields.each do |v|
      if v == "*"
        select_string += " #{collection_name}.#{v} "
      else
        select_string += " #{collection_name}.`#{v}` "
      end
    end

    statement = "SELECT META().id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} WHERE #{statement};"

    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values))
  end

  private def process_args(args)
    JSON.parse(
      args.to_json
    )
  end
end