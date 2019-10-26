package com.zhouraohust.spark.mlib

import org.apache.spark.SparkConf
import org.apache.spark.ml.clustering.KMeans
import org.apache.spark.ml.feature.VectorAssembler
import org.apache.spark.sql.{DataFrame, SaveMode, SparkSession}

import scala.util.Random

/**
 * 描述:${DESCRIPTION}
 *
 * @author zhourao
 * @create 2019-10-26 10:42 上午
 */
object KmeasRFM {

  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setMaster("local").setAppName("iris")
    val spark = SparkSession.builder().config(conf).getOrCreate()

    val file = spark.read.format("csv").load("/data/test/rfm_1.csv")
    file.show()

    import spark.implicits._
    val random = new Random()
    val data = file.map(row => {
      (row.getString(0).toDouble,
        row.getString(1).toDouble,
        row.getString(2).toDouble,
        row.getString(3),
        random.nextDouble())
    }).toDF("R", "F", "M", "customer_id", "rand").sort("rand")
    val assembler = new VectorAssembler()
      .setInputCols(Array("R", "F", "M"))
      .setOutputCol("features")

    val dataset = assembler.transform(data)
    val Array(train, test) = dataset.randomSplit(Array(0.8, 0.2))

    val kmeans = new KMeans().setFeaturesCol("features").setK(8).setMaxIter(200000)
    val model = kmeans.fit(train)

    val frame = model.transform(train)
    frame.show()
    val csvData = frame.map(row => {
      (row.getDouble(0),
        row.getDouble(1),
        row.getDouble(2),
        row.getString(3),
        row.getInt(6))
    }).toDF("R", "F", "M", "customer_id","RANK")

    csvData.coalesce(1).write.mode(SaveMode.Append).format("com.databricks.spark.csv")
      .option("header", "true")
      .csv("/data/test/output.csv")
  }
}
