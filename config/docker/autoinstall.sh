
#Warning: This script is not tested and may not work properly

echo "This script is not tested and may not work properly"
echo "Do you want to continue? (y/n)"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Continuing"
else
    echo "Exiting"
    exit 1
fi

#Check if Docker is installed
if [ -x "$(command -v docker)" ]; then
    echo "Docker is already installed"
else
    echo "Docker is not installed"
    echo "Installing Docker"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    echo "Docker installed"
fi

#Create Docker Container Volumes

#Mosquitto Volumes
docker volume create mosquitto_data
docker volume create mosquitto_log
docker volume create mosquitto_conf

#Node-Red Volumes
docker volume create node_red_data

#InfluxDB Volumes
docker volume create influxdb

#Grafana Volumes
docker volume create grafana

#Create Docker Container

#Mosquitto
docker run -it -d \
    -p 1883:1883 \
    -p 9001:9001 \
    -v mosquitto_conf:/mosquitto/config \
    -v mosquitto_data:/mosquitto/data \
    -v mosquitto_log:/mosquitto/log \
    --restart=always \
    --name=mosquitto-server \
    eclipse-mosquitto:latest

#Node-Red
docker run -it -d \
    -p 1880:1880 \
    -v node_red_data:/data \
    --name=mynodered \
    --restart=always \
    nodered/node-red:latest

#InfluxDB
docker run -it -d \
    -p 8086:8086 \
    -v influxdb:/var/lib/influxdb \
    --name=influxdb \
    --restart=always \
    influxdb:1.8

#Grafana
docker run -it -d \
    -p 3000:3000 \
    --name=grafana \
    -v grafana:/var/lib/grafana \
    --name=grafana \
    --restart=always \
    grafana/grafana:latest

#Erstellt im InfuxDB Datenbank "pv"
docker exec influxdb influx -execute "CREATE DATABASE e3dc"