import psycopg2

# Establish a connection to the database
conn = psycopg2.connect(
    database="mydb",
    user="pguser",
    password="mypguser123",
    host="localhost",
    port="5432"
)

# Create a cursor object
cur = conn.cursor()

# Define the SQL command to check if the table exists
check_table_command = """
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_name = 'TESTDB'
    )
"""

check_table_command = """
SELECT EXISTS (
    SELECT FROM 
        pg_tables
    WHERE 
        schemaname = 'public' AND 
        tablename  = 'testdb'
    );
"""



# Execute the SQL command to check if the table exists
cur.execute(check_table_command)

# Fetch the result of the command
table_exists = cur.fetchone()[0]


# If the table doesn't exist, create it
print(table_exists)
if not table_exists:
    create_table_command = """
        CREATE TABLE TESTDB (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            age INT NOT NULL,
            email VARCHAR(255) NOT NULL
        )
    """
    cur.execute(create_table_command)
    conn.commit()

# Define the SQL command to insert sample data into the table
insert_data_command = """
    INSERT INTO TESTDB (name, age, email) 
    VALUES ('John Doe', 35, 'johndoe@example.com'),
           ('Jane Smith', 42, 'janesmith@example.com'),
           ('Bob Johnson', 27, 'bobjohnson@example.com')
"""

# Execute the SQL command to insert the sample data
cur.execute(insert_data_command)
conn.commit()

# Define the SQL command to select all rows from the table
select_all_rows_command = """
    SELECT * FROM TESTDB
"""

# Execute the SQL command to select all rows from the table
cur.execute(select_all_rows_command)

# Fetch all rows from the result set
rows = cur.fetchall()

# Print the rows
for row in rows:
    print(row)

# Close the cursor and the connection
cur.close()
conn.close()
