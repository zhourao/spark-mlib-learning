#!/bin/bash
# 钉钉服务告警函数
function alarmEvent ()
{
        DATE_STR=`date +"%Y-%m-%d %H:%M:%S"`
        # 告警地址\
        ALARM_URL="https://oapi.dingtalk.com/robot/send?access_token=2cf9814f72b14be3012696626df8a31c1cbf53a36412c790559509fb2de3963f"
        DING="curl -H \"Content-Type: application/json\" -X POST --data '{
        \"msgtype\":\"text\",\"text\":{\"content\":\"【任务名称】:$1\n【任务环境】:$2\n【告警信息】:任务停止\n【告警时间】:${DATE_STR}\"}
        }' ${ALARM_URL}"
        eval ${DING}
        exit 1
}
profile=$1
# 定时比较逻辑告警
while true
do
        # 获取配置的任务id
	str=(`cat ./jobConf.txt | awk -F ' ' '{print $1}'`)
	declare -A map=() #定义
	for i in ${!str[@]}
	do

	#赋值
	eval $(echo ${str[i]} | awk '{split($0, fileArray, ":");print "map["fileArray[1]"]="fileArray[2]}')
	done
	CONF_ID=${!map[@]}

	# 获取yarn任务的applicationId
	YARN_ID=`yarn application -list 2>/dev/null|grep application_|awk '{ print $1 }'`
	NEED_ALARM=0
    JOB_NAME=''

	# 比较配置id以及运行id
       for cid in  ${CONF_ID}; do
        if echo "${YARN_ID[@]}" | grep -w ${cid} &>/dev/null;then
		NEED_ALARM=0
	else
               NEED_ALARM=1
               JOB_NAME=${map[$cid]}
               break
        fi
        done
        # applicationId已丢失 需要发送告警
        if [[ ${NEED_ALARM} -eq 1 ]]; then
                alarmEvent ${JOB_NAME} ${profile}
        fi
        sleep 5
done