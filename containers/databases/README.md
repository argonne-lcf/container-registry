# Databases

Two ways to use databases on Polaris, you can either pull an image from a repository or build images from scratch on a compute node.
For the latter you will need a .def file and request a compute node using qsub by setting the singularity_fakeroot flag to true.

```bash
qsub -I -A <project_name> -q debug -l select=1 -l walltime=60:00 -l singularity_fakeroot=true -l filesystems=home:eagle:grand
```

We provide singularity containers and steps to interact with database containers on Polaris. To use this you will have to load singularity module and set the proxy on the compute/login node.
```bash
module load singularity
#For compute nodes set proxy variable
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
```

## Mongo DB
MongoDB is a cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with optional schemas. MongoDB is developed by MongoDB Inc.

### How to use MongoDB on Polaris
1. Pull container from Argonne GitHub container registry
```bash
singularity pull oras://ghcr.io/argonne-lcf/mongo:latest
```

2. Create a data and logs directory to bind to the running container
```bash
mkdir -p $PWD/data
```

3. Running mongo
```bash
singularity exec --bind $PWD/data:/data/db mongo_latest.sif mongod
```
OR
To run it as an instance in the background. You can
```bash
singularity instance start --bind $PWD/data:/data/db mongo_latest.sif mongoinstance
```

To stop the instance
```bash
singularity instance stop mongoinstance
```

To list all running instances
```bash
singularity instance list
```

### PyMongo
Pymongo is the Python client/library to connect to a running mongodb. Query and interact with your data directly from Python. Here's an example

```bash
> module load conda
> conda activate base #do this once
> python3 -m venv ~/envs/mongoenv #do this once
> source ~/envs/mongoenv/bin/activate
> python3
>>> import pymongo 
>>> import pprint
>>> mongo_uri = "mongodb://localhost:27017/" 
>>> dbclient = pymongo.MongoClient(mongo_uri)
>>> appdb = dbclient["blog"]
>>> appcoll = appdb["blogcollection"]
>>> document = {"user_id": 1, "user": "test"}
>>> appcoll.insert_one(document)
<pymongo.results.InsertOneResult object at 0x7f3b63469790>
>>> dbclient.list_database_names()
['admin', 'blog', 'config', 'local']
```

## Neo4j
Neo4j is the world's leading open source Graph Database which is developed using Java technology. It is highly scalable and schema free (NoSQL).

### What is a Graph Database?
A graph is a pictorial representation of a set of objects where some pairs of objects are connected by links. It is composed of two elements - nodes (vertices) and relationships (edges).

Graph database is a database used to model the data in the form of graph. In here, the nodes of a graph depict the entities while the relationships depict the association of these nodes.

### How to use Neo4j on Polaris
1. 1. Pull container from Argonne GitHub container registry
```bash
singularity pull oras://ghcr.io/argonne-lcf/neo4j:latest
```

2. Create a data and logs directory to bind to the running container
```bash
mkdir -p $PWD/data
mkdir -p $PWD/logs
```

3. Create a persistent overlay for the container. A persistent overlay is a directory or file system image that “sits on top” of your immutable SIF container. When you install new software or create and modify files the overlay will store the changes.
```bash
singularity overlay create --size 1024 overlay.img
```

4. Run the container
```bash
singularity exec -B $PWD/data:/data -B $PWD/logs:/logs --overlay overlay.img neo4j_latest.sif neo4j start
Directories in use:
home:         /var/lib/neo4j
config:       /var/lib/neo4j/conf
logs:         /var/lib/neo4j/logs
plugins:      /var/lib/neo4j/plugins
import:       /var/lib/neo4j/import
data:         /var/lib/neo4j/data
certificates: /var/lib/neo4j/certificates
licenses:     /var/lib/neo4j/licenses
run:          /var/lib/neo4j/run
Starting Neo4j.
WARNING: Max 16384 open files allowed, minimum of 40000 recommended. See the Neo4j manual.
Started neo4j (pid:50867). It is available at http://localhost:7475
There may be a short delay until the server is ready.
```
5. To view neo4j database on your browser and interact with the database you can ssh tunnel to the login node where the service is running. It can be polaris-login-XX as shown below

```bash
export PORT=7475 export PORT1=7687; ssh -L "localhost:${PORT}:localhost:${PORT}" -L "localhost:${PORT1}:localhost:${PORT1}" <username>@<polaris-login-01>.alcf.anl.gov
```

## PostgreSQL
PostgreSQL also known as Postgres, is a free and open-source relational database management system (RDBMS) emphasizing extensibility and SQL compliance.

### How to use Postgres on Polaris
1. Pull container from docker
```bash
singularity pull --name postgres.simg docker://postgres
```

2. Now create an environment file
```bash
cat >> pg.env <<EOF
export POSTGRES_USER=pguser
export POSTGRES_PASSWORD=mypguser123
export POSTGRES_DB=mydb
export POSTGRES_INITDB_ARGS="--encoding=UTF-8"
EOF
```

3. Create a data and run directory to bind to the running container
```bash
mkdir pgdata
mkdir pgrun
```

4. Start an instance of the container
```bash
singularity instance start -B pgdata:/var/lib/postgresql/data -B pgrun:/var/run/postgresql postgres.simg postgres
```

5. Run the container
```bash
singularity run instance://postgres &
```

6. To run a sample code to connect to POSTGRES. You can refer to the [postgres_test.py](postgres/postgres_test.py) file
```bash
>module load conda
>conda activate base #do this once
>python3 -m venv ~/envs/postgres_env # do this once
>source ~/envs/postgres_env/bin/activate
>pip install -r $PWD/requirements.txt
>python3 $PWD/postgres_test.py
```

7. When done, stop the postgres container instance.

```bash
singularity instance stop postgres
```
## MYSQL
MySQL is an open-source relational database management system

### How to use MySQL on Polaris
1. Pull container from Dockerhub
```bash
singularity pull --name mysql.simg docker://mysql
```

2. Create local directories for MySQL. These will be bind-mounted into the container and allow other containers to connect to the database via a local socket as well as for the database to be stored on the host filesystem and thus persist between container instances.

```bash
mkdir -p ${PWD}/mysql/var/lib/mysql ${PWD}/mysql/run/mysqld
```

3. Set the root password for mysql using the environment variable Start the singularity instance for the MySQL server

```bash
export MYSQL_ROOT_PASSWORD=mysecretpw
singularity instance start --bind ${HOME} \
    --bind ${PWD}/mysql/var/lib/mysql/:/var/lib/mysql \
    --bind ${PWD}/mysql/run/mysqld:/run/mysqld \
    ./mysql.simg mysql
```

4. Run the container startscript to initialize and start the MySQL server. Note that initialization is only done the first time and the script will automatically skip initialization if it is not needed. This command must be run each time the MySQL server is needed (e.g., each time the container is spun-up to provide the MySQL server).

```bash
singularity run instance://mysql &
```

5. A sample code to connect to MySQL, refer to the [mysql_test.py](mysql/mysql_test.py) file. Below are steps to run a python script to connect to a running MySQL instance. 
```bash
>module load conda
>conda activate base #do this once
>python3 -m venv ~/envs/mysql_env # do this once
>source ~/envs/pymongo_env/bin/activate
>pip install -r databases/requirements.txt
>python3 $PWD/mysql_test.py
```

6. When done, stop the MySQL container instance.

```bash
singularity instance stop mysql
```

