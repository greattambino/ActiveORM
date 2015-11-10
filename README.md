# Active ORM

Active ORM is an Object-Relational Mapping framework inspired by ActiveRecord
- Utilizes meta programming to bridge the gap between Ruby and SQL
- Implements the DBConnection class to execute custom-built SQL queries and has_many and has_through associations

Demo:
-----
1. Clone ``git clone https://github.com/greattambino/ActiveORM.git``
2. Run:
  - ``$ rake db:create``
  - ``$ ruby demo.rb``
3. Open ``demo.rb`` and go crazy!


[![Screenshot](/doc/screenshot.png)](https://github.com/greattambino/ActiveORM.git)

Usage:
------
```ruby
# rake db:create generates a seeded db/cats.sql database
require_relative 'lib/active_record_lite'

# open database connection
DBConnection.open('db/cats.sqlite3')
```

Next, define a model and its associations:
```ruby
class Cat < ActiveRecordBase
  belongs_to :human, foreign_key: :owner_id
  has_one_through :house, :human, :house

  finalize!
end
```

By specifying ``finalize!``, we allow mass-assignment:
```ruby
president = Human.new(fname: 'Barack', lname: 'Obama', house_id: 1)
pet = Cat.new(name: 'Garfield', owner_id: 1)
```

There is support for ``has_many``, ``belongs_to``, and ``has_one_through``

By convention, we assume that the column used to hold the foreign key on this model is the name of the association with the suffix_id added. The ``:foreign_key`` option lets you set the name of the foreign key directly, along with the ``:class_name`` and ``:primary_key``:

```ruby
has_many :cats,
  foreign_key: :owner_id,
  class_name: 'Cat',
  primary_key: :id
```

To override a default table name, call ``table_name= "new_name"``:

```ruby
class Human < ActiveRecordBase
  table_name= 'humans' # example of overriding table name

  has_many :cats, foreign_key: :owner_id
  belongs_to :house

  finalize!
end
```

Schema:
------
Manipulate the schema in the ``db/cats.sql`` file.

```sql
CREATE TABLE cats (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  owner_id INTEGER,

  FOREIGN KEY(owner_id) REFERENCES human(id)
);

INSERT INTO
  cats (id, name, owner_id)
VALUES
  (1, "Breakfast", 1),
  (2, "Earl", 2),
  (3, "Haskell", 3),
  (4, "Markov", 3),
  (5, "Stray Cat", NULL);
```
---
Developed by [Marc Tambara](http://www.MarcTambara.com)
