# Connect PostgreSQL exporter container
sudo docker network connect constant_network rough_work-postgres_exporter-1

# Connect Prometheus container
sudo docker network connect constant_network rough_work-prometheus-1

# Connect Grafana container
sudo docker network connect constant_network rough_work-grafana-1

# Connect PostgreSQL container
sudo docker network connect constant_network api-test-sonar_db-1

# Connect Jenkins container
sudo docker network connect constant_network jenkins


In the exporter setup we given the database name only.this will throwh DNS resolving error. So take the ip adrress and update in the exporter setup.


#sudo docker exec -it api-test-sonar_db-1 /bin/bash

#echo "listen_addresses = '*'" >> /var/lib/postgresql/data/postgresql.conf


#172.18.0.0/16 is the network range in the containesr of constant_network
#cat /var/lib/postgresql/data/postgresql.conf | grep listen_addresses

#echo "host    all             all             172.18.0.0/16           md5" >> /var/lib/postgresql/data/pg_hba.conf

#cat /var/lib/postgresql/data/pg_hba.conf | grep 172.18.0.0

#172.24.0.4

give some time it will take some time.