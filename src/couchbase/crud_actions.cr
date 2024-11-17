module CrudActions
  extend self

  def start_transaction
    CouchbaseQuery.new(statement: "START TRANSACTION", scan_consistency: "request_plus", durability_level: "none")
  end

  def rollback_transaction(txid : UUID)
    CouchbaseQuery.new(statement: "ROLLBACK TRANSACTION", txid: txid)
  end

  def commit_transaction(txid : UUID)
    CouchbaseQuery.new(statement: "COMMIT TRANSACTION", txid: txid)
  end

  def all(collection_name, fields : Array(String | Hash(String, String) | Hash(String, Array(String))) = ["*"], excluded_fields : Array(String) = [] of String, limit : Int32 = 0, offset : Int32 = 0, joins : Array(Couchbase::Join) = [] of Couchbase::Join)
    select_string = gen_search_string(fields, collection_name, excluded_fields)
    group_by_string = "GROUP BY META(#{collection_name}).id, "
    group_by_string += select_string unless joins.empty?
    select_string += gen_join_selects(joins) unless joins.empty?
    join_string = gen_join_string(joins)

    limit_string = ""

    limit_string += " LIMIT #{limit} OFFSET #{offset}"if limit > 0
    
    CouchbaseQuery.new(statement: "SELECT META(#{collection_name}).id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} #{join_string} #{joins.empty? ? "" : group_by_string}#{limit_string};")
  end

  def insert(collection_name : String, values, txid : UUID? = nil)
    CouchbaseQuery.new(statement: "INSERT INTO #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} (KEY, VALUE) VALUES (UUID(), #{values.to_json}) RETURNING META().id, #{collection_name}.*;", txid: txid)
  end

  def update_by_id(collection_name, id, values, txid : UUID? = nil)
    statement = "UPDATE #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} USE KEYS \"#{id}\" SET "
    values.each do |key, value|
      next if key.to_s == "id"
      statement += "`#{key}` = #{value.to_json}, "
    end
    statement = statement.chomp(", ") + " RETURNING META().id, #{collection_name}.*;"
    
    CouchbaseQuery.new(statement: statement, txid: txid)
  end

  def update_where(collection_name, values, conditions, txid : UUID? = nil)
    statement = "UPDATE #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name}.#{collection_name} SET "

    values.each do |key, value|
      next if key.to_s == "id"
      statement += "`#{key}` = #{value.to_json}, "
    end
    statement = statement.chomp(", ")
    
    where_clause = conditions.map do |k, v|
      key = k.to_s == "id" ? "META(#{collection_name}).id" : "`#{k}`"
      if v.is_a?(Array)
        "#{key} in ?"
      else
        "#{key} = ?"
      end
    end.join(" AND ")
    
    statement += " WHERE #{where_clause} RETURNING META().id as id, #{collection_name} as document;"
    
    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values), txid: txid)
  end

  def delete_by_id(collection_name, id, txid : UUID? = nil)
    statement = "DELETE FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} USE KEYS \"#{id}\" RETURNING META().id, #{collection_name}.*;"
    CouchbaseQuery.new(statement: statement, txid: txid)
  end

  def delete_where(collection_name, conditions, txid : UUID? = nil)
    statement = "DELETE FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} "

    where_clause = conditions.map do |k, v|
      key = k.to_s == "id" ? "META(#{collection_name}).id" : "`#{k}`"
      if v.is_a?(Array)
        "#{key} in ?"
      else
        "#{key} = ?"
      end
    end.join(" AND ")
    
    statement += " WHERE #{where_clause} RETURNING META().id, #{collection_name};"

    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values), txid: txid)
  end

  def select_by_id(collection_name, id, fields : Array(String | Hash(String, String) | Hash(String, Array(String))) = ["*"], excluded_fields : Array(String) = [] of String, joins : Array(Couchbase::Join) = [] of Couchbase::Join)
    select_string = gen_search_string(fields, collection_name, excluded_fields)
    group_by_string = "GROUP BY META(#{collection_name}).id, "
    group_by_string += select_string unless joins.empty?
    select_string += gen_join_selects(joins) unless joins.empty?
    join_string = gen_join_string(joins)

    CouchbaseQuery.new "SELECT META(#{collection_name}).id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} #{join_string} USE KEYS \"#{id}\" #{joins.empty? ? "" : group_by_string};"
  end

  def select_by(collection_name, conditions, fields : Array(String | Hash(String, String) | Hash(String, Array(String))) = ["*"], excluded_fields : Array(String) = [] of String, limit : Int32 = 0, offset : Int32 = 0, joins : Array(Couchbase::Join) = [] of Couchbase::Join)
    select_string = gen_search_string(fields, collection_name, excluded_fields)
    group_by_string = "GROUP BY META(#{collection_name}).id, "
    group_by_string += select_string unless joins.empty?
    select_string += gen_join_selects(joins) unless joins.empty?
    join_string = gen_join_string(joins)

    where_clause = conditions.map do |k, v|
      key = k.to_s == "id" ? "META(#{collection_name}).id" : "`#{k}`"
      if v.is_a?(Array)
        "#{key} in ?"
      else
        "#{key} = ?"
      end
    end.join(" AND ")

    limit_string = ""

    limit_string += " LIMIT #{limit} OFFSET #{offset}"if limit > 0

    statement = "SELECT META(#{collection_name}).id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} #{join_string} WHERE #{where_clause} #{joins.empty? ? "" : group_by_string}#{limit_string};"

    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values))
  end

  def select(collection_name, statement, args, fields : Array(String | Hash(String, String) | Hash(String, Array(String))) = ["*"], excluded_fields : Array(String) = [] of String, limit : Int32 = 0, offset : Int32 = 0, joins : Array(Couchbase::Join) = [] of Couchbase::Join)
    select_string = gen_search_string(fields, collection_name, excluded_fields)
    group_by_string = "GROUP BY META(#{collection_name}).id, "
    group_by_string += select_string unless joins.empty?
    select_string += gen_join_selects(joins) unless joins.empty?
    join_string = gen_join_string(joins)

    limit_string = ""

    limit_string += " LIMIT #{limit} OFFSET #{offset}"if limit > 0

    statement = "SELECT META(#{collection_name}).id AS id, #{select_string} FROM #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{collection_name} #{join_string} WHERE #{statement} #{joins.empty? ? "" : group_by_string}#{limit_string};"

    CouchbaseQuery.new(statement: statement, args: process_args(conditions.values))
  end

  private def process_args(args)
    JSON.parse(
      args.to_json
    )
  end

  private def gen_search_string(fields, collection_name, excluded_fields)
    select_fields = [] of String

    if excluded_fields.empty?
      fields.each do |v|
        if v.is_a?(Hash)
          v.each do |inner_k, inner_v|
            values = [] of String
            if inner_v.is_a?(String)
              values << "'#{inner_v}': #{collection_name}.`#{inner_k}`.`#{inner_v}` "
            else
              inner_v.each do |inner_innver_v|
                values << "'#{inner_innver_v}': #{collection_name}.`#{inner_k}`.`#{inner_innver_v}` "
              end
            end
            select_fields <<"{#{values.join(",")}} as #{inner_k}"
          end
        elsif v == "*"
          select_fields << "#{collection_name}.#{v}"
        elsif v == "id"
          next
        else
          select_fields << "#{collection_name}.`#{v}`"
        end
      end
    else
      excluded_fields_str = excluded_fields.map { |field| "'#{field}'" }.join(", ")

      select_fields << "(OBJECT_REMOVE(#{collection_name}, #{excluded_fields_str})).*"
    end

    select_fields.join(", ")
  end

  private def gen_join_selects(joins)
    join_select_string = [] of String

    joins.each do |join|
      join_select_string << "COALESCE(ARRAY_AGG(OBJECT_CONCAT({'id': META(#{join.join_2_name}).id}, #{join.join_2_name})), []) AS #{join.join_name}" if join.relationship_type == Couchbase::Join::RelationshipType::MANY
      join_select_string << "ARRAY_AGG(OBJECT_CONCAT({'id': META(#{join.join_2_name}).id}, #{join.join_2_name}))[0] AS #{join.join_name}" if join.relationship_type == Couchbase::Join::RelationshipType::ONE
    end

    return ", #{join_select_string.join(", ")} "
  end

  private def gen_join_string(joins)
    return "" unless joins.size

    join_string = [] of String

    joins.each do |join|
      destination_join = join.join_2_field == "id" ? "META(#{join.join_2_name}).id" : "#{join.join_2_name}.#{join.join_2_field}"
      origin_join = join.join_1_field == "id" ? "META(#{join.join_1_name}).id" : "#{join.join_1_name}.#{join.join_1_field}"
      join_string << "#{join.join_type.to_s} JOIN #{Couchbase.settings.bucket_name}.#{Couchbase.settings.scope_name}.#{join.join_2_name} ON #{destination_join} = #{origin_join}"
    end

    join_string.join(" ")
  end
end