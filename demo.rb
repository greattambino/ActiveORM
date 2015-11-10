require_relative 'lib/active_record_orm'

# show verbose queries
ENV['DEBUG'] = 'true'

# open database connection
DBConnection.open('db/cats.sqlite3')


# define cat model
class Cat < ActiveRecordBase
  # columns :id, :name, :owner_id

  belongs_to :human, foreign_key: :owner_id
  has_one_through :house, :human, :house

  finalize!
end

# define human model
class Human < ActiveRecordBase
  table_name= 'humans' # example of overriding table name
  # columns :id, :fname, :lname, :house_id

  has_many :cats, foreign_key: :owner_id
  belongs_to :house

  finalize!
end

# define house model
class House < ActiveRecordBase
  # columns :id, :address
  # specify class_name, foreign_key, primary_key (defaults are identical in this case)
  has_many :humans,
    class_name: 'Humans',
    foreign_key: :house_id,
    primary_key: :id

  finalize!
end

puts 'simply find queries:'
puts '-------------------'
cat = Cat.find(2)
puts "cat = Cat.find(2)       => #{cat.inspect}"
puts "cat.name                => #{cat.name}"

puts

human = Human.find(1)
puts "human = Human.find(1)   => #{human.inspect}"
puts "human.fname             => #{human.fname}"

puts

puts 'belongs_to associations:'
puts '-----------------------'
puts "cat.human               => #{cat.human.inspect}"
puts "cat.human.fname:        => #{cat.human.fname}"
puts "human.house.address:    => #{human.house.address}"

puts

puts 'has_many associations:'
puts '---------------------'
puts "human.cats              => #{human.cats.inspect}"

puts

puts 'has_one_through associations:'
puts '----------------------------'
puts "cat.house               => #{cat.house.inspect}"
puts "cat.house.address:      => #{cat.house.address}"
