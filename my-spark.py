from pyspark import SparkContext
from operator import add

import shutil

# In case of empty value
def to_int(val):
    if val == "":
        return 0
    else:
        return int(val)

# Getting Spark context
sc = SparkContext()

# Getting .csv
tf = sc.textFile("data.csv")
# header = tf.first()

# rdd = tf.map(lambda line: line.split(";")).filter(lambda line: line != header).map(lambda line: (line[3], to_int(line[6])))
rdd = tf.map(lambda line: line.split(";")).map(lambda line: (line[3], to_int(line[6])))

# rdd = rdd.reduceByKey(lambda a, b: a + b)
rdd = sc.parallelize(sorted(rdd.reduceByKey(lambda a, b: a + b).collect()))

# To delete output directory in the HDFS : hdfs dfs -rm -r output

# Saving
# try:
#     shutil.rmtree("output")
# except FileNotFoundError:
#   print("Output directory does not exist")

rdd.saveAsTextFile("output")
