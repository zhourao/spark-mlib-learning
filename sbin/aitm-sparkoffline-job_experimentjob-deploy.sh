#!/bin/bash
mainClassName="com.yupaopao.aitm.offline.scala.job.update.aitm.experimentjob"
appName=`echo ${mainClassName} | awk -F "." '{print $NF}'`
releaseSuc='发布成功'
killFail='停止失败'
startFail='启动失败'
profile=${profiles.active}

function remindEvent ()
{
        DATE_STR=`date +"%Y-%m-%d %H:%M:%S"`
        # 任务启动成功地址\
        REMIND_URL="https://oapi.dingtalk.com/robot/send?access_token=2cf9814f72b14be3012696626df8a31c1cbf53a36412c790559509fb2de3963f"
        DING="curl -H \"Content-Type: application/json\" -X POST --data '{
        \"msgtype\":\"text\",\"text\":{\"content\":\"【任务环境】:$3\n【通知内容】:$1任务$2\n【通知时间】:${DATE_STR}\"}
        }' ${REMIND_URL}"
        eval ${DING}
}

function failEvent ()
{
        DATE_STR=`date +"%Y-%m-%d %H:%M:%S"`
        REMIND_URL="https://oapi.dingtalk.com/robot/send?access_token=2cf9814f72b14be3012696626df8a31c1cbf53a36412c790559509fb2de3963f"
        # 任务停止失败\
        DING="curl -H \"Content-Type: application/json\" -X POST --data '{
        \"msgtype\":\"text\",\"text\":{\"content\":\"【任务环境】:$3\n【通知内容】:$1任务$2\n【通知时间】:${DATE_STR}\"}
        }' ${REMIND_URL}"
        eval ${DING}
        exit 1
}

base_path=$(cd `dirname $0`; pwd)
source /etc/profile
p_num=`yarn application -list -appStates RUNNING|awk '{print $1,$2}'|grep -Ee "${appName}"|wc -l`
if [[ ${p_num} -gt 0 ]];then
   echo 'job is RUNNING,START RESTART'
   app_id=`yarn application -list -appStates RUNNING|awk '{print $1,$2}'|grep -Ee "${appName}"|awk '{print $1}'`
   yarn application -kill ${app_id}
   sleep 20
   n_num=`yarn application -list -appStates RUNNING|awk '{print $1,$2}'|grep -Ee "${appName}"|wc -l`
   if [[ ${n_num} -gt 0 ]];then
      echo 'JOB KILL FAIL'
      failEvent ${appName} ${killFail} ${profile}
   fi
   nohup ${base_path}/spark-submit.sh ${mainClassName} ${profile} >> ${base_path}/output.log 2>&1 &
   echo 'JOB RESTART END'
else
   echo 'job is SHUTDOWN'
   nohup ${base_path}/spark-submit.sh ${mainClassName} ${profile}>> ${base_path}/output.log 2>&1 &
   echo 'job is RESTART'
fi
sleep 60
job_num=`yarn application -list -appStates RUNNING|awk '{print $1,$2}'|grep -Ee "${appName}"|wc -l`
if [[ ${job_num} -gt 0 ]];then
    echo 'JOB START SUCCESS'
    remindEvent ${appName} ${releaseSuc} ${profile}
else
    echo 'JOB RESTART FAIL'
    failEvent ${appName} ${startFail} ${profile}
fi
app_conf=`yarn application -list 2>/dev/null|grep  -Ee "${appName}" |grep application_|awk '{ print $1":"$2}'`
echo ${app_conf} > ${base_path}/jobConf.txt
nohup sh ${base_path}/job-monitor.sh ${profile} 2>/dev/null &