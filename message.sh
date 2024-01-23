# Copyright [2023] [esuoyanyu]. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

TASK_STATE="task_table"

#message fromat
#1	2	3	 4	5
#文件名	总大小	已下载大小  任务ID   下载状态

#$1-文件
record_total_size() {
	flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w "$1" | awk '{print $2}')"
	#cat "$TASK_STATE" | grep -w "$1" | awk '{print $2}'
}

#$1-文件
record_loading_size() {
	flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w "$1" | awk '{print $3}')"
}

#$1-文件
record_task_id() {
	flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w "$1" | awk '{print $4}')"
}

#$1-文件
record_down_state() {
	flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w "$1" | awk '{print $5}')"
}

#$1-同步目录
record_done_total() {
	id=$(echo $1 | sed "s#\/#\\\/#g")
	ID=$(flock -s "$TASK_STATE" -c "echo $(cat $TASK_STATE | awk 'find==1 && /^\[/ {exit} /\['$id'\]/ {find=1} find==1 && /^[^[]/ && /'$DOWNER_DONE'/ {printf("%s ", $2);}')")
	#echo "id=$ID end"
	total=$(echo $ID | wc -w)

	echo $total
}

#$1-同步目录
record_loading_total() {
	id=$(echo $1 | sed "s#\/#\\\/#g")
	ID=$(flock -s "$TASK_STATE" -c "echo $(cat $TASK_STATE | awk 'find==1 && /^\[/ {exit} /\['$id'\]/ {find=1} find==1 && /^[^[]/ && /'$DOWNER_LOADING'/ {printf("%s ", $2);}')")
	#echo "id=$ID end"
	total=$(echo -e $ID | wc -w)

	echo $total
}

#$1-文件 $2-同步的目录 $3-大小
set_loading_size() {
	total=$(record_total_size $1)
	state=$(record_down_state $1)
	taskID=$(record_task_id $1)
	#echo "toal=$total state=$state taskID=$taskID"
	ret=$(flock -s "$TASK_STATE" -c "cat $TASK_STATE | grep -e "$1"")
	if [ "$ret" != "" ]; then
		remove_record $1  $2
		add_record $1 $2 $total $3 $taskID $state
	fi
}

#$1-文件 $2-同步的目录 $3-状态
set_down_state() {
	loading=$(record_loading_size $1)
	total=$(record_total_size $1)
	taskID=$(record_task_id $1)
	#echo "toal=$total loading=$loading taskID=$taskID"
	ret=$(flock -s "$TASK_STATE" -c "cat "$TASK_STATE" | grep -e "$1"")
	if [ "$ret" != "" ]; then
		remove_record $1  $2
		add_record $1 $2 $total $loading $taskID $3
	fi
}

#$1-url $2-同步的目录 $3-总大小 $4-已下载大小 $5-任务ID $6-下载状态
add_record() {
	is=$(flock -s "$TASK_STATE" -c "cat "$TASK_STATE" | grep "\[$2\]"")
	if [ "$is" != "" ]; then
		#echo "add_record=$TASK_STATE"
		id=$(echo $2 | sed "s#\/#\\\/#g")
		#echo "$id"
		flock -x "$TASK_STATE" -c "$(echo "$(cat "$TASK_STATE" | sed "/^\[${id}\]/a ${1} ${3} ${4} ${5} ${6}")" > "$TASK_STATE")"
	fi
}

#$1-url
remove_record() {
	line=$(flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w -n $1 | awk -F':' '{print $1}')")
	flock -x "$TASK_STATE" -c "$(echo -e $(cat "$TASK_STATE" | sed "$line d" | sed -z "s#\n#\\\n#g") > "$TASK_STATE")"
	#echo "remove TASK_STATE=$TASK_STATE"
}

#message fromt
# 1	2	3
# 文件	任务ID	 状态

#$1-文件
sub_task_id() {
	flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w "\[$1\]" | awk '{print $2}')"
}

#$1-文件
sub_task_state() {
	flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -w "\[$1\]" | awk '{print $3}')"
}

#无参数
sub_task_running_total() {
	ID=$(flock -s "$TASK_STATE" -c "echo $(cat $TASK_STATE | awk ' /^\[/ && /'$TASK_RUNNING'/ {printf("%s ", $2);}')")
	#echo "id=$ID end"
	total=$(echo $ID | wc -w)

	echo $total
}

#无参数
sub_task_done_total() {
	ID=$(flock -s "$TASK_STATE" -c "echo $(cat $TASK_STATE | awk ' /^\[/ && /'$TASK_DONE'/ {printf("%s ", $2);}')")
	total=$(echo "$ID" | wc -w)

	echo $total
}

#需要验证
#$1-同步的目录
sub_task_all_record_id() {
	id=$(echo $1 | sed "s#\/#\\\/#g")
	list=$(flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | awk 'find==1 && /^\[/ {exit} /\['$id'\]/ {find=1} find==1 && /^[^[]/ {printf("%s ", $4);}')")

	echo $list
}

#需要验证
#$1-文件 $2-任务状态
set_sub_task_state() {
	ID=$(sub_task_id $1)
	if [ "$ID" != "" ]; then
		flock -x "$TASK_STATE" -c "$(sed -i "/^[${1}]/c [${1}] ${ID} ${2}" "$TASK_STATE")"
	fi
}

#$1-要同步的目录 $2-任务ID $3-状态
add_sub_task() {
	flock -x "$TASK_STATE" -c "$(echo "[$1] $2 $3" >> "$TASK_STATE")"
}

#$1-文件
remove_sub_task() {
	echo "remove_sub_task not supported"
}

#message fromt
# 1		2
# taskID	状态

#需要验证
#$1-taskID $2-状态
set_task_state() {
	ret=$(flock -s "$TASK_STATE" -c "echo $(cat "$TASK_STATE" | grep -e "^$1")")
	if [ "$ret" != "" ]; then
		flock -s "$TASK_STATE" -c "$(sed -i "/^$1/c ${1} ${2}"  $TASK_STATE)"
	fi
}

# $1-保存信息的目录
sync_task_info() {
	flock -s "$TASK_STATE" -c "$(echo "$(cat $TASK_STATE)" > $1)"
	sync
}

# $1-任务ID $2 状态
add_task() {
	flock -x "$TASK_STATE" -c "$(echo "$1 $2" > "$TASK_STATE")"
}

# $1-任务ID
remove_task() {
	flock -x "$TASK_STATE" -c "truncate -s 0 "$TASK_STATE""
}

export TASK_RUNNING="running"
export TASK_DONE="done"
export DOWNER_LOADING="loading"
export DOWNER_DONE="done"


test() {
	add_task "123" "running"
	add_sub_task "/home/chy/work" "456" "running"
	sub_task_id "/home/chy/work"
	sub_task_state "/home/chy/work"
	sub_task_running_total "/home/chy/work"


	set_task_state "123" "done"
	#set_sub_task_state "/home/chy/work" "done"

	sub_task_done_total

	add_record "/home/chy/work/test" "/home/chy/work" 4096 2048 123 "$DOWNER_LOADING"
	sync_task_info ./test/sync-file.log

	sub_task_all_record_id "/home/chy/work"

	add_record "/home/chy/work/test1" "/home/chy/work" 512 1 123 "$DOWNER_LOADING"
	sync_task_info ./test/sync-file.log

	add_sub_task "/home/chy/work1" "456" "running"
	add_record "/home/chy/work/tet1" "/home/chy/work1" 520 0 123 "ru"
	record_total_size "/home/chy/work/test"

	record_loading_size "/home/chy/work/test"
	sync_task_info ./test/sync-file.log


	set_loading_size "/home/chy/work/test" "/home/chy/work" 1024

#	sync_task_info ./test/sync-file.log

	set_down_state "/home/chy/work/test" "/home/chy/work" "done"

	#sync_task_info ./test/sync-file.log

	record_done_total "/home/chy/work"
	record_loading_total "/home/chy/work"

	#remove_task
}

#test
