#!/bin/bash
set -x -e
classname=$1
profiles=$2
appName=`echo ${classname} | awk -F "." '{print $NF}'`

base_path=$(cd `dirname $0`; pwd)

HADOOP_USER_NAME=hdfs \
spark-submit \
        --conf "spark.master=yarn" \
        --conf "spark.submit.deployMode=cluster" \
        --conf "spark.app.name=${appName}" \
        --conf "spark.driver.cores=2" \
        --conf "spark.driver.memory=512M" \
        --conf "spark.driver.memoryOverhead=1G" \
        --conf "spark.executor.memory=512M" \
        --conf "spark.executor.memoryOverhead=1G" \
        --conf "spark.executor.cores=2" \
        --conf "spark.default.parallelism=100" \
        --conf "spark.sql.shuffle.partitions=60" \
        --conf "spark.dynamicAllocation.enabled=true" \
        --conf "spark.dynamicAllocation.maxExecutors=5" \
        --conf "spark.dynamicAllocation.minExecutors=2" \
        --conf "spark.dynamicAllocation.executorIdleTimeout=60" \
        --conf "spark.dynamicAllocation.cachedExecutorIdleTimeout=60" \
        --conf "spark.driver.extraJavaOptions=-Dlog4j.configuration=log4j.properties" \
    --files "$base_path/log4j.properties" \
    --jars "/opt/cloudera/parcels/CDH/lib/kafka/libs/*.jar" \
    --driver-java-options " -Duser.timezone=Asia/Shanghai -Dclient.encoding.override=UTF-8 -Dfile.encoding=UTF-8 -Duser.region=CN -Djava.net.preferIPv4Stack=true"\
    --conf spark.driver.extraJavaOptions=" -Dspring.profiles.active=${profiles} -Dfile.encoding=utf-8 " \
    --conf spark.executor.extraJavaOptions=" -Dspring.profiles.active=${profiles} -Dfile.encoding=utf-8 " \
    --class ${classname} \
${base_path}/aitm-sparkoffline-job_${appName}.jar