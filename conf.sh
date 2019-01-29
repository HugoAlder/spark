# 172.28.100.76 spark-1
# 172.28.100.85 spark-2
# 172.28.100.73 spark-3
# 172.28.100.88 spark-4

sudo apt update && sudo apt install openjdk-8-jre-headless openjdk-8-jdk-headless
echo "JAVA_HOME=\"/usr/lib/jvm/java-1.8.0-openjdk-amd64\"" | sudo tee -a /etc/environment

# wget http://apache.mirrors.spacedump.net/hadoop/common/stable/hadoop-2.9.2.tar.gz
tar xvf hadoop-2.9.2.tar.gz
rm -f hadoop-2.9.2.tar.gz

export HADOOP_PREFIX="/home/ubuntu/hadoop-2.9.2"
export PATH="$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin:$PATH"

# =================================================== CORE_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/core-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://spark-1:9000</value>
    </property>
</configuration>
EOF
# =================================================== CORE_SITE

# =================================================== HDFS_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
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
EOF
# =================================================== HDFS_SITE


# =================================================== MAPRED_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
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
EOF
# =================================================== MAPRED_SITE

# =================================================== YARN_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
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
EOF
# =================================================== YARN_SITE

# =================================================== SLAVES
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/slaves
spark-2
spark-3
spark-4
EOF
# =================================================== SLAVES

# sudo vim /etc/hostname
# 172.28.100.76 spark-1
# 172.28.100.85 spark-2
# 172.28.100.73 spark-3
# 172.28.100.88 spark-4

# sudo sh -c 'echo "127.0.0.1 `cat /etc/hostname`" >> /etc/hosts'
# sudo sh -c 'echo "172.28.100.76 spark-1" >> /etc/hosts'
# sudo sh -c 'echo "172.28.100.85 spark-2" >> /etc/hosts'
# sudo sh -c 'echo "172.28.100.73 spark-3" >> /etc/hosts'
# sudo sh -c 'echo "172.28.100.88 spark-4" >> /etc/hosts'

wget http://apache.crihan.fr/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz
tar xvf spark-2.4.0-bin-hadoop2.7.tgz
mv spark-2.4.0-bin-hadoop2.7 spark

export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop
export SPARK_HOME=/home/hadoop/spark
export LD_LIBRARY_PATH=/home/hadoop/hadoop/lib/native:$LD_LIBRARY_PATH

cat <<EOF > $SPARK_HOME/conf/spark-defaults.conf
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
EOF

