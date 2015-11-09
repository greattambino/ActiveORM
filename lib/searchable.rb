require_relative 'db_connection'

module Searchable
  def where(params)
    where_line = params.keys.map { |key| "#{key} = ?"}.join(" AND ")
    vals = params.values
    query = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL

    query.map { |attrs| self.new(attrs) }
  end
end
