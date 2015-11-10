require_relative 'db_connection'
require_relative './searchable.rb'
require_relative './associatable.rb'
require 'active_support/inflector'

class ActiveRecordBase
  extend Searchable
  extend Associatable

  def self.columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    cols.first.map!(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method("#{col}") do
        attributes[col]
      end
    end

    self.columns.each do |col|
      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name};
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  def self.find(id)
    query = <<-SQL
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?;
    SQL

    puts "[QUERY] \n#{query} => #{id}" if ENV['DEBUG']

    results = DBConnection.execute(query, id)
    self.parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      sym = attr_name.to_sym
      unless self.class.columns.include?(sym)
        raise "unknown attribute '#{attr_name}'"
      else
        self.send("#{attr_name}=", val)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map{ |ivar| self.send(ivar) }
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name}(#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_values = self.class.columns.drop(1).
      map { |col| "#{col} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1), id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_values}
      WHERE
        id = ?;
    SQL
  end

  def save
    id ? update : insert
  end
end
