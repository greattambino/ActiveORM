require 'active_support/inflector'
require_relative 'searchable'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] ||= (name.to_s.underscore + "_id").to_sym
    @class_name = options[:class_name] ||= name.to_s.camelcase
    @primary_key = options[:primary_key] ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] ||= (self_class_name.to_s.underscore + "_id").to_sym
    @class_name = options[:class_name] ||= name.to_s.singularize.camelcase
    @primary_key = options[:primary_key] ||= :id
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      primary_key = options.primary_key
      foreign_key = self.send(options.foreign_key)

      query = <<-SQL
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{primary_key} = ?;
      SQL

      puts "[QUERY] \n#{query} => #{foreign_key}" if ENV['DEBUG']

      options.model_class.where(
        "#{options.table_name}.#{primary_key}" => foreign_key
      ).first
    end

    self.assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      primary_key = self.send(options.primary_key)
      foreign_key = options.foreign_key

      query = <<-SQL
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.table_name}.#{foreign_key} = ?;
      SQL

      puts "[QUERY] \n#{query} => #{primary_key}" if ENV['DEBUG']

      options.model_class.where("#{options.table_name}.#{foreign_key}" => primary_key)
    end

  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      source_table = source_options.table_name
      through_table = through_options.table_name

      query = <<-SQL
        SELECT
          #{source_table}.*
        FROM
          #{source_table}
        JOIN
          #{through_table} ON #{through_table}.#{source_options.foreign_key} =
            #{source_table}.#{source_options.primary_key}
        WHERE
          #{through_table}.#{through_options.primary_key} = ?;
      SQL

      value = self.send(through_options.foreign_key)

      puts "[QUERY] \n#{query} => #{value}" if ENV['DEBUG']

      attrs = DBConnection.execute(query, self.send(through_options.foreign_key))
      source_options.model_class.parse_all(attrs).first
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end
