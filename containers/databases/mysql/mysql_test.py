import mysql.connector

# Establish a connection to the MySQL server
cnx = mysql.connector.connect(user='root', password='mysecretpw',
                              host='localhost',port='3306')

# Create a cursor object to interact with the database
cursor = cnx.cursor()

# Create a new database
create_db_query = "CREATE DATABASE IF NOT EXISTS mydatabase"
cursor.execute(create_db_query)

# Switch to the new database
use_db_query = "USE mydatabase"
cursor.execute(use_db_query)

# Create a table
create_table_query = """CREATE TABLE IF NOT EXISTS users (
                            id INT AUTO_INCREMENT PRIMARY KEY,
                            name VARCHAR(255) NOT NULL,
                            email VARCHAR(255) NOT NULL
                        )"""
cursor.execute(create_table_query)

# Insert data into the table
insert_query = "INSERT INTO users (name, email) VALUES (%s, %s)"
values = ("John Doe", "john.doe@example.com")
cursor.execute(insert_query, values)

# Commit the changes to the database
cnx.commit()

# Fetch the records from the table
select_query = "SELECT * FROM users"
cursor.execute(select_query)
records = cursor.fetchall()

# Print the records
for record in records:
    print(record)


# Close the cursor and connection to the database
cursor.close()
cnx.close()
