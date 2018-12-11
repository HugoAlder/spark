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
header = tf.first()

rdd = tf.map(lambda line: line.split(";")).filter(lambda line: line != header).map(lambda line: (line[3],line[6]))

rdd = sc.parallelize(sorted(rdd.reduceByKey(add).collect()))

# Saving
try:
    shutil.rmtree("output")
except FileNotFoundError:
    print("Output directory does not exist")

rdd.saveAsTextFile("output")
