# Das Repository ist derzeit noch in der Beta!

# e3dc-to-grafana
Dies ist meine Dokumentation/Lösung wie ich die Daten von meinem e3dc Hausgraftwerk in ein Grafana-Dashboard anzeige. Dazu verwende ich das fertige Script von [pvtom](https://github.com/pvtom/rscp2mqtt). In meinem fall lese ich die Daten von einem e3dc X10 Speichers aus, welches super funktioniert.
Hier ein Schaubild wie die Datenflüsse sind:
![e3dc-to-grafana](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/doku/e3dc-to-grafana.jpg)

## Voraussetzungen

* e3dc Speicher
* PI oder Rechner(mit Linux installiert) wo Docker laufen kann.

## Installation

### e3dc Speicher
Kommen wir nun zur Installation. Als erstes müssen wir am e3dc Speicher die RSCP Schnittstelle aktivieren. Dazu gehen wir direkt zum Speicher. Dort wählen wir "Einstellungen" und dann "Personalisieren". Dort können wir "RSCP" aktivieren. Dies machen wir indem wir ein Passwort vergeben. Ich habe auch den Lokalen RSCP User ein Passwort vergeben um sicherzugehen dass alles funktioniert. Dieses Passwort wird später in der Konfiguration benötigt. Nun müssen wir noch die IP Adresse des e3dc Speichers herausfinden. Dazu gehen wir wieder auf die Einstellungen und wählen "Netzwerk". Dort finden wir die IP Adresse des e3dc Speichers. Bei bedarf kann du dort auch die IP Adresse ändern oder auf Static stellen damit der Speicher immer die gleiche IP Adresse hat.

### Docker
Als nächstes müssen wir wenn nicht schon vorhanden Docker installieren. Dazu folge bitte die Anleitung auf der [Docker](https://docs.docker.com/get-docker/) Seite. Dort findest du auch Anleitungen für andere Betriebssysteme. 

Alternative hab ich ein Scirpt geschrieben, welches Docker installiert und alle nachfolgenden Schritte ausführt. Dieses Script findest du [hier](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/config/docker/autoinstall.sh). (Achtung, dieses Script ist noch nicht getestet.)

Wir gehen jedoch den manuellen Weg.
Als erstes müssen wir einige Volumen erstellen. Dazu führen wir folgenden Befehl aus:
```bash
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
```

Nun können wir schon die Container erstellen und Starten. Dazu führen wir folgende Befehle aus:
```bash
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

```
Mit diesen Befehlen haben wir nun die Container erstellt und gestartet. Mit dem Befehl `docker ps` können wir nun überprüfen ob die Container gestartet wurden.

### Configuration der Container

### Node-Red
Starte deinen Browser, gib die IP mit dem Port 1180 ein wo du die Container gestartet. Es öffnet sich Node-RED, dort klicken wir auf das Menü oben rechts und wählen "Import". Dort kopierst du die Datei [e3dc_NodeRED.json](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/config/NodeRED/e3dc_NodeRED.json#L948) und fügst sie ein. Bevor du auf Import klickst, musst du einmal die IP deines MQTT-Brockers eingeben und die IP deiner InfluxDB außerdem ist es notwenig deine Datenbank anzugeben, diese wird später configuriert. Nun kannst du auf Import klicken. Nach dem Import soll dies so aussehen: ![NodeRED_Example](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/examples/NodeRED_Config.png)

### Mosquitto
Der Mosquitto Container welcher der MQTT Broker ist, muss ebenfalls Configuriert werden. Wenn du die Anleitung befolgt hast, befindet sich die Config Datei unter `/var/lib/docker/volumes/mosquitto_conf/_data`. Dort öffnest du die Datei `mosquitto.conf` und fügst folgende Zeilen hinzufügen:
```bash
allow_anonymous true
```
Die erlaubt einfach anmelden ohne Passwort. Wenn du dies nicht möchtest findest du im Internet eine Anleitung wie du ein Passwort für den MQTT Broker einrichtest.

### InfluxDB
Als nächstes müssen wir noch die Datenbank in InfluxDB erstellen. Dazu geben wir im Terminal folgenden Befehl ein:
```bash
docker exec influxdb influx -execute "CREATE DATABASE e3dc"
```
Mit diesem Befehl haben wir nun die Datenbank 'e3dc' erstellt.

### Grafana
Um auf die Grafana Login Site zu kommen müssen wir den Port 3000 verwenden. Also geben wir in unserem Browser die IP mit dem Port 3000 ein. Dort geben als Username admin und als Passwort admin ein. Als nächstes müssen wir das Passwort ändern.
Nun können wir schonmal die Datenbank hinzufügen. Dazu klicken wir auf das Menü oben links und wählen "Data Sources". Dort klicken wir auf "Add data source" und wählen "InfluxDB". Dort geben wir als Name InfluxdBPV an. Als URL die IP mit dem Port 8086 ein. Als Datenbank wählen wir "e3dc". Als User und Passwort lassen wir frei. Nun können wir auf "Save & Test" klicken. Nun sollte die Datenbank hinzugefügt sein.

### rspc2mqtt
Nun müssen wir das rspc2mqtt Script installieren. Leider hab ich es nicht hinbekommen dieses Script in Docker zu installieren. Deshalb muss es auf dem Rechner installiert werden. Dazu befolge bitte die schritte aus dem [rspc2mqtt](https://github.com/pvtom/rscp2mqtt) Repository. Dort findest du auch eine Anleitung wie du das Script installierst. In der Config Datei musst du nun die IP Adresse des e3dc Speichers, das Passwort und die IP Adresse des MQTT Brokers eintragen. Zum Schluss muss das Scirpt gestartet werden. In meinem Fall läuft es als Dienst. Wie du dies machst findest du ebenfallst im genannten Repository.

### Erster Test
Nun können wir testen ob alles funktioniert.
Um zu überprüfen ob beim MQTT Broker Daten ankommen, können wir das Programm [MQTT Explorer](https://mqtt-explorer.com/) verwenden. Dort geben wir als Broker die IP Adresse des MQTT Brokers ein. Als Port geben wir 1883 ein. Username und Passwort lassen wir frei. Nun können wir auf Connect klicken. Es sollte ein Abschnitt mit dem Namen "e3dc" angezeigt werden. Dort sollten sich Daten vom PV-Speicher befinden. Hier ein Beispiel:
![MQTT Explorer](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/examples/mqtt ausgabe.png)

Um zu überprüfen ob die Daten in der InfluxDB ankommen habe ich ein Test Dashboard für Grafana erstellt. Hir findest du die [Test-Dashboard.json](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/config/Grafana/test_dashboard.json#L2835). 
Dies soll in etwa so aussehen: ![Test Dashboard](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/examples/test_dashboard.png)

### Grafana Dashboard
Ich habe mir die Mühe gemacht für meine Bedürfnisse ein Dashboard zu erstellen. Dieses findest du [hier](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/config/Grafana/e3dc_dashboardv1.json). Dieses Dashboard soll in etwa so aussehen: ![Dashboard](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/examples/e3dc_dashboardv1.png)

Bitte vegiss nicht die Richtige Datenbank auszuwählen. In meinem Fall ist es die Datenbank "e3dc" und der Name im Grafana lautet "InfluxDB-PV".

## Sonstiges
Ich hab das RSCP2MQTT Script so konfiguriert, dass dieses als Dienst läuft.

Leider werden Einige Werte in meinem Fall nicht regelmäßig aktualisiert. Deshalb habe ich einen Cronjob erstellt der alle 6 Stunden den rspc2mqtt Dienst neustartet. Dieser Cronjob sieht wie folgt aus:
```bash
0 */6 * * * systemctl restart rspc2mqtt
```
Außerdem befindet sich [hier](https://github.com/MrIceman11/e3dc-to-grafana/blob/main/doku/mqtt_Werte-Ausgabe.txt) eine Dokumentatoin über die Daten die der e3dc Speicher an den MQTT Broker sendet. Leider hatte ich nicht die Zeit alle Werte zu überprüfen. Falls du einen Fehler findest, kannst du mir gerne eine Nachricht schreiben.

## Credits
Ich möchte mich bei dem Entwickler von [rspc2mqtt](https://github.com/pvtom/rscp2mqtt) für die Tolle Arbeit bedanken. Das hat mir sehr viel Arbeit abgenommen.
