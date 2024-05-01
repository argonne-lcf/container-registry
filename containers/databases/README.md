# Databases

There are two ways to use databases on Polaris: you can either pull an image from a repository or build images from scratch on a compute node.

For the latter, you will need a .def file and must request a compute node using qsub by setting the singularity_fakeroot flag to true, or you can do this directly on the login node.

```bash
qsub -I -A <project_name> -q debug -l select=1 -l walltime=60:00 -l singularity_fakeroot=true -l filesystems=home:eagle
```
ALCF provides Apptainer as its container runtime of choice. To use Apptainer on Polaris:

```bash
module use /soft/spack/gcc/0.6.1/install/modulefiles/Core
module load apptainer
#For compute nodes set proxy variable
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
```

Following are examples of different databases that can be run on Polaris:

## PostgreSQL
PostgreSQL also known as Postgres, is a free and open-source relational database management system (RDBMS) emphasizing extensibility and SQL compliance.

### How to use Postgres on Polaris
* Pull container from docker
```bash
apptainer build postgres.sing docker://postgres
```

* Now create an environment file
```bash
cat >> pg.env <<EOF
export POSTGRES_USER=pguser
export POSTGRES_PASSWORD=mypguser123
export POSTGRES_DB=mydb
export POSTGRES_INITDB_ARGS="--encoding=UTF-8"
EOF
```

* Create a data and run directory to bind to the running container
```bash
mkdir -p pgdata pgrun
```

* Start an instance of the container

```bash
apptainer instance run -C --env-file pg.env -B pgdata:/var/lib/postgresql/data -B pgrun:/var/run/postgresql postgres.sing postgres
```

* Check if postgres instance is running

```bash
apptainer instance list
INSTANCE NAME    PID        IP    IMAGE

postgres         2176232          /home/atanikanti/postgres.sing
```

* Ensure proxy variables are not set

```bash
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
```

* connect using client to the container
```bash
apptainer exec instance://postgres psql -U pguser
```

* To run a sample code to connect to POSTGRES. You can refer to the [postgres_test.py](postgres/postgres_test.py) file

```bash
module use /soft/modulefiles/
module load conda/2024-04-29 
conda create -n postgres_env python==3.11.8 --y
conda activate postgres_env
pip install psycopg2-binary
python3 postgres/postgres_test.py
```

* When done, stop the postgres container instance.

```bash
apptainer instance stop postgres
```

## Mongo DB
MongoDB is a cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with optional schemas. MongoDB is developed by MongoDB Inc.

### How to use MongoDB on Polaris
* Pull container

```bash
apptainer build --fakeroot mongo.sing docker://mongo
```

* Create a data and logs directory to bind to the running container

```bash
mkdir -p $PWD/data
```

* Running mongo

```bash
apptainer instance run -C -B data:/data/db mongo.sing mongo
```

* To stop the instance
```bash
apptainer instance stop mongo
```

* To list all running instances
```bash
apptainer instance list
```

### PyMongo
Pymongo is the Python client/library to connect to a running mongodb. Query and interact with your data directly from Python. Here's an example [pymongo_test.py](mongo/pymongo_test.py) file

```bash
module use /soft/modulefiles/
module load conda/2024-04-29 
conda create -n pymongo_env python==3.11.8 --y
conda activate pymongo_env
pip install pymongo
python3 mongo/pymongo_test.py
```

## Neo4j
Neo4j is the world's leading open source Graph Database which is developed using Java technology. It is highly scalable and schema free (NoSQL).

### What is a Graph Database?
A graph is a pictorial representation of a set of objects where some pairs of objects are connected by links. It is composed of two elements - nodes (vertices) and relationships (edges).

Graph database is a database used to model the data in the form of graph. In here, the nodes of a graph depict the entities while the relationships depict the association of these nodes.

### How to use Neo4j on Polaris
* Pull container from Argonne GitHub container registry
```bash
apptainer pull oras://ghcr.io/argonne-lcf/neo4j:latest
```

* Create a data and logs directory to bind to the running container
```bash
mkdir -p $PWD/data
mkdir -p $PWD/logs
```

* Create a persistent overlay for the container. A persistent overlay is a directory or file system image that “sits on top” of your immutable SIF container. When you install new software or create and modify files the overlay will store the changes.
```bash
apptainer overlay create --size 1024 overlay.img
```

* Run the container
```bash
apptainer exec -B $PWD/data:/data -B $PWD/logs:/logs --overlay overlay.img neo4j_latest.sif neo4j start
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
* To view neo4j database on your browser and interact with the database you can ssh tunnel to the login node where the service is running. It can be polaris-login-XX as shown below

```bash
export PORT=7475 export PORT1=7687; ssh -L "localhost:${PORT}:localhost:${PORT}" -L "localhost:${PORT1}:localhost:${PORT1}" <username>@<polaris-login-01>.alcf.anl.gov
```


## MYSQL
MySQL is an open-source relational database management system

### How to use MySQL on Polaris
* Pull container from Dockerhub
```bash
apptainer build mysql.simg docker://mysql
```

* Create local directories for MySQL. These will be bind-mounted into the container and allow other containers to connect to the database via a local socket as well as for the database to be stored on the host filesystem and thus persist between container instances.

```bash
mkdir -p ${PWD}/mysql/var/lib/mysql ${PWD}/mysql/run/mysqld
```

* Set the root password for MySQL using the environment variable. Start the Apptainer instance for the MySQL server:

```bash
export MYSQL_ROOT_PASSWORD=mysecretpw
apptainer instance run -C -B ${PWD} \
    --bind ${PWD}/mysql/var/lib/mysql/:/var/lib/mysql \
    --bind ${PWD}/mysql/run/mysqld:/run/mysqld \
    ./mysql.simg mysql
```

* A sample code to connect to MySQL, refer to the [mysql_test.py](mysql/mysql_test.py) file. Below are steps to run a python script to connect to a running MySQL instance. 
```bash
module use /soft/modulefiles/
module load conda/2024-04-29 
conda create -n mysqlenv python==3.11.8 --y
conda activate mysqlenv
pip install mysql-connector-python
python3 $PWD/mysql_test.py
```

* When done, stop the MySQL container instance.

```bash
apptainer instance stop mysql
```

## Redis
Redis is an open-source, in-memory data structure store, used as a database, cache, and message broker. It supports data structures such as strings, hashes, lists, sets, sorted sets with range queries, bitmaps, hyperloglogs, geospatial indexes with radius queries, and streams. Redis has built-in replication, Lua scripting, LRU eviction, transactions, and different levels of on-disk persistence.

### How to use Redis on Polaris

* Pull the Redis container from DockerHub

```bash
apptainer build redis.sif docker://redis
```

* Create a directory for Redis data to ensure data persistence

```bash
mkdir -p $PWD/redisdata
```

* Start an instance of the Redis container, binding the persistent data directory

```bash
apptainer instance run -C -B redisdata:/data redis.sif redis-server --appendonly yes
```

* Verify that the Redis instance is running

```bash
apptainer instance list
```

* Connect to the Redis instance using the Redis CLI

```bash
apptainer exec instance://redis redis-cli
```

* Example Redis operations: setting a key and retrieving it

```bash
SET mykey "Hello, Redis!"
GET mykey
```
