# SID - TP Spark

## Objectifs du TP

Le but de ce TP est d'apprendre à utiliser les technologies Hadoop et Spark afin de pouvoir lancer un programme de façon distribuée sur un cluster de machines.

Apache Hadoop est un framework libre et open-source qui a pour but de faciliter la création d'applications distribuées au niveau du stockage et du traitement des données.

Apache Spark est un framework libre et open-source qui fournit un bon nombre d'outils utiles pour la programmation distribuée. Initialement prévu pour fonctionner avec le langage de programmation Scala, nous avons décidé d'utiliser le langage Python, avec lequel nous avons plus d'expérience, et qui est lui aussi compatible.

Afin d'apprendre à utiliser ces outils, nous allons analyser les données trouvées sur le site [opendata.lillemetropole.fr](https://opendata.lillemetropole.fr/explore/dataset/naissances-par-commune-departement-et-region-de-2003-a-2013/table/). Notre objectif sera de comptabiliser le nombre de naissances par commune grâce au modèle MapReduce.

Vous pouvez consulter notre répertoire GitHub [ici](https://github.com/HugoAlder/spark).

## Utilisation de Spark en local

Nous avons commencé par installer PySpark (Spark pour Python) sur une seule machine afin de tester notre code localement.

Nous utilisons des RDD afin de parcourir notre fichier CSV initial et ainsi obtenir les informations voulues grâce à une opération de Map/Reduce.

Pour le Map, nous séparons les champs par ";" tout en passant le header, puis nous ne sélectionnons que ceux qui nous intéressent, à savoir _Libellé Gréographique_ et _Naissances._ Le résultat est stocké dans un RDD.

Pour le Reduce, nous recoupons les données par la clef _Libellé Géographique_, puis nous ajoutons toutes les valeurs associées à une même clef pour obtenir enfin le nombre de naissances par commune.

## Installation du cluster

Pour la suite de ce projet, nous avons créé 4 machines sur l'OpenStack de l'université afin de pouvoir créer une cluster Hadoop. Le nœud master de ce cluster sera spark-1. Les nœuds esclaves seront slave-2, slave-3 et slave-4.

L'ensemble des commandes utilisées pour installer le cluster son disponible dans le script bash disponible dans notre dépôt GitHub.

### Configurations préliminaires

Pour commencer, il faut mettre en communications les différentes machines du cluster. Il faut rajouter dans les fichiers */etc/hosts* de chaque machine les lignes suivantes :

```
172.28.100.76 spark-1
172.28.100.85 spark-2
172.28.100.73 spark-3
172.28.100.88 spark-4
```

Il faut ensuite rajouter les clefs ssh publiques de chaque machine dans le fichier authorized_key de chaque autre machine.

Ajouter la variable d'environnement *HADOOP_PREFIX* sur chaque machine et l'ajouter au *PATH*.

```
export HADOOP_PREFIX="/home/ubuntu/hadoop-2.9.2"
export PATH="$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin:$PATH"
```

Pour indiquer quelles sont les machines esclaves dans le cluster, éditer le fichier *$HADOOP_PREFIX/etc/hadoop/slaves*.

```
spark-2
spark-3
spark-4
```

### HDFS

#### Installation de Java

Nous avons commencé par mettre les paquets de toute les machines à jours tout en installant le JDK. Il faut aussi créer une variable d'environnement *JAVA_HOME*.

```
sudo apt update && sudo apt install openjdk-8-jre-headless openjdk-8-jdk-headless
echo "JAVA_HOME=\"/usr/lib/jvm/java-1.8.0-openjdk-amd64\"" | sudo tee -a /etc/environment
```
#### Téléchargement des fichiers Hadoop

Il faut ensuite télécharger les fichiers binaires de Hadoop et extraire l'archive. On supprime ensuite l'archive.
```
wget http://apache.mirrors.spacedump.net/hadoop/common/stable/hadoop-2.9.2.tar.gz
tar xvf hadoop-2.9.2.tar.gz
rm -f hadoop-2.9.2.tar.gz
```

#### Configuration de Hadoop

Le **NameNode** gère les fichiers distribués dans tout le cluster. Il faut donc modifier le fichier *core-site.xml* pour indiquer qu'il s'agit de slave-1.

```
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://spark-1:9000</value>
    </property>
</configuration>
```
Les données d'un nœud particulier sont gérées par un **Datanode**, alors que la gestion des processus d'un nœud est assurée par un **NodeManager**. Il faut indiquer au HDFS où stocker les données pour que ces deux entités fonctionnent. On indique ensuite combien de fois les données doivent être répliquées sur le cluster. Il faut ajouter les lignes suivantes au fichier *hdfs-site.xml*.
```
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
            <name>dfs.namenode.name.dir</name>
            <value>/home/ubuntu/data/nameNode</value>
    </property>
    <property>
            <name>dfs.datanode.data.dir</name>
            <value>/home/ubuntu/data/dataNode</value>
    </property>
    <property>
            <name>dfs.replication</name>
            <value>1</value>
    </property>
</configuration>
```
#### Utilisation du HDFS

Pour formater le HDFS, lancer la commande `hdfs namenode -format`. Puis lancer la commande `start-dfs.sh` pour lancer tous les démons nécessaires.

Pour créer un répertoire qui contient tous les fichiers à prendre en input, lancer la commande `hdfs dfs -mkdir inputs`. Ce répertoire est créé dans le répertorie home du HDFS, à savoir */user/ubuntu*.

Pour déposer le fichier de données dans le répertoire créé, lancer la commande `hdfs dfs -put data.csv inputs`.

### YARN

C'est le framework Yarn qui s'occupe l'ordonnancement des jobs sur le cluster. Pour configurer les ressources maximales que chaque nœud peut utiliser, comme la mémoire utilisée, il faut ajouter les lignes suivantes au fichier *mapred-site.xml*.
```
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
        <property>
                <name>yarn.app.mapreduce.am.resource.mb</name>
                <value>512</value>
        </property>
        <property>
                <name>mapreduce.map.memory.mb</name>
                <value>256</value>
        </property>
        <property>
                <name>mapreduce.reduce.memory.mb</name>
                <value>256</value>
        </property>
</configuration>
```

Pour configurer les ressources utilisées par un conteneur Yarn dans un nœud du cluster, il faut modifier *yarn-site.xml*.

La propriété `yarn.nodemanager.resource.memory-mb` permet de fixer la mémoire allouée à un conteneur.\
La propriété `yarn.scheduler.maximum-allocation-mb` permet de fixer la mémoire maximum allouée à un conteneur.\
La propriété `yarn.scheduler.minimum-allocation-mb` permet de fixer la mémoire minimum allouée à un conteneur.\
La propriété `mapreduce.map.memory.mb` permet de fixer la mémoire allouée à une opération de map.\
La propriété `mapreduce.reduce.memory.mb` permet de fixer la mémoire allouée à une opération de reduce.\
La propriété `yarn.app.mapreduce.am.resource.mb` permet de fixer la mémoire allouée à l'ApplicationMaster (la principale application d'un ResourceManager).

```
<?xml version="1.0"?>
<configuration>
    <property>
            <name>yarn.acl.enable</name>
            <value>0</value>
    </property>
    <property>
            <name>yarn.resourcemanager.hostname</name>
            <value>spark-1</value>
    </property>
    <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
    </property>
        <property>
                <name>yarn.nodemanager.resource.memory-mb</name>
                <value>1536</value>
        </property>
        <property>
                <name>yarn.scheduler.maximum-allocation-mb</name>
                <value>1536</value>
        </property>
        <property>
                <name>yarn.scheduler.minimum-allocation-mb</name>
                <value>128</value>
        </property>
        <property>
                <name>yarn.nodemanager.vmem-check-enabled</name>
                <value>false</value>
        </property>
</configuration>
```
Finalement, pour lancer le démon Yarn, lancer la commande `start-yarn.sh` depuis le nœud maître.


### Spark

#### Téléchargement

Commencer par télécharger les fichiers binaires.

```
wget http://apache.crihan.fr/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
tar xvf spark-2.3.2-bin-hadoop2.7.tgz
mv spark-2.3.2-bin-hadoop2.7 spark
```

#### Configuration

Pour configurer Spark, il faut ajouter les lignes suivantes au fichier *.profile* du nœud maître.

```
export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop
export SPARK_HOME=/home/hadoop/spark
export LD_LIBRARY_PATH=/home/hadoop/hadoop/lib/native:$LD_LIBRARY_PATH
```

Ajouter les lignes suivantes au fichier *$SPARK_HOME/conf/spark-defaults.conf*.

```
spark.master                      yarn
spark.driver.memory               512m
spark.yarn.am.memory              512m
spark.executor.memory             512m
spark.eventLog.enabled            true
spark.eventLog.dir                hdfs://spark-1:9000/spark-logs
spark.history.provider            org.apache.spark.deploy.history.FsHistoryProvider
spark.history.fs.logDirectory     hdfs://spark-1:9000/spark-logs
spark.history.fs.update.interval  10s
spark.history.ui.port             18080
```
La propriété `spark.master` indique que nous utilisons yarn pour interagir avec le cluster.\
La propriété `spark.driver.memory` indique que nous allouons 512Mo au pilote Spark en mode cluster.\
La propriété `spark.yarn.am.memory`indique que nous allouons 512Mo à l'ApplicationMaster en mode client.\
La propriété `spark.executor.memory` indique que nous allouons 512Mo aux calculs.\

Les propriétés restantes sont utilisées afin de configurer le serveur de logs afin que celui-ci puisse se greffer au HDFS.

Pour créer le dossier de logs, lancer la commande `hdfs dfs -mkdir /spark-logs`. Puis, pour lancer le serveur d'historique, lancer la commande `$SPARK_HOME/sbin/start-history-server.sh`.

#### Utilisation

Pour lancer un script Python sur le cluster, il faut lancer les commandes suivante depuis le nœud master. Pour exécuter le script de manière distribuée, il faut préciser la valeur `cluster` à l'option `--deploy-mode`. Pour le lancer sur une seule machine, utiliser la commande la valeur `client`.

```
spark-submit --deploy-mode cluster my-script
```

Le résultats de l'exécution du code se trouvera dans le dossier *output* du HDFS. On retrouve bien un total du nombre de naissances par commune.

### Remarques

#### Volume des données et performances

Compte-tenu du faible volume de données avec lequel nous avons réalisé nos tests, nous obtenons des performances contradictoires avec ce que l'on pouvait croire de prime abord. En effet, l'exécution de notre code prend plus de temps quand il est lancé via Hadoop en mode cluster par rapport à une exécution réalisée sur une seul machine. Sur le cluster, l'exécution de notre code prend 52 secondes, contre 6.4 secondes sur une seule machine.

Nous pensons que cela est dû au fait qu'Hadoop demande pas mal de temps et de ressources lors du lancement préliminaire à l'exécution effective de notre code, comme le temps nécessaire à la préparation des noeuds, ... Ce temps de préparation peut être négligé lors du traitement de volumes de données bien plus gros, mais il devient non-négligeable lors de l'exécution d'un petit volume de données.

#### Comportement des nœuds

Nous avons vérifié que chaque nœud du cluster est bien utilisé pour exécuter notre code en lançant une commande `htop` sur chaque machine afin de pouvoir observer l'activité de leur CPU. Cependant, il s'avère que les différentes machines du cluster ne sont pas utilisées en même temps, ce qui est contre-intuitif dans le contexte de la programmation distribuée. Nous ne savons pas si s'agit d'un comportement normal de Hadoop ou non.
