# Copyright [2023] [esuoyanyu]. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

export TASK_RUNNING="running"
export TASK_DONE="done"
export DOWNER_LOADING="loading"
export DOWNER_DONE="done"

source message.sh

# $1-进程ID
create_task() {
	add_task $1 $TASK_RUNNING
}

# $1-要同步目录列表
destory_task() {
	for item in $1; do
		destroy_downloader $item
	done
}

# $1-进程ID $2-总数 $3-保存进程信息
update_task() {
	done_total=$(downloader_done_total $1)
	if [ $done_total -gt $2 ]; then
		set_task_state $TASK_DONE
		echo "$TASK_DONE"
	fi

	sync_task_info $3
}

# $1-要同步的目录 $2-保存的目录
create_downloader() {
	#1. get file list
	file_list=$(_file_list $1)
	if [ "$file_list" == "" ]; then
		return 1
	fi

	add_sub_task $1 $$ 0 $TASK_RUNNING
	while true; do
		for item in $file_list; do
			url=$(echo $item | awk '{print $1}')
			total=$(echo $item | awk '{print $2}')
			sub_dir="${url#*$1}"
			save_file="$2/$sub_dir"

			update_record $save_file
			check_record $save_file $1
			if [ $? -eq 0 ]; then
				create_record $url $save_file $1 $total &
			fi
		done

		total=$(echo $file_list | wc -l)
		state=$(update_downloader $1 $total)
		if [ "$state" == "$TASK_DONE" ]; then
			break
		fi
	done

	#remove_sub_task
}

# $1-要同步的目录
destroy_downloader() {
	task_id=$(sub_task_all_record_id $1)
	for item in $task_id; do
		destroy_record $item
	done

	task_id=$(sub_task_id $1)
	kill -9 $task_id
	wait $task_id
}

# $1-要同步的目录 $2-要下载的总数
update_downloader() {
	done_total=$(record_done_total $1)
	if [ $done_total -eq $2 ]; then
		set_sub_task_state $TASK_DONE
		echo "$TASK_DONE"
	fi
}

# $1-要同步的目录
check_downloader() {
	running_total=$(downloader_running_total $dir)
	if [ $running_total -gt $DOWER_TOTAL ]; then
		return 1
	fi

	state=$(sub_task_state $1)
	if [ "$state" == "" ];then
		return 0
	fi

	return 1
}

# $1-要同步的目录
downloader_running_total() {
	sub_task_running_total $1
}

# $1-要同步的目录
downloader_done_total() {
	sub_task_done_total $1
}

# $1-要同步的文件 $2-要保存的文件 $3-同步的目录 $4-总大小
create_record() {
	save_dir=$(dirname $2)
	if [ ! -d "$save_dir" ]; then
		mkdir -p "$save_dir"
	fi

	donwloader $1 $save_dir 
	add_record $2 $3 $4 0 $$ $DOWNER_LOADING
}

# $1-taskID
destroy_record() {
	kill -9 $1
	wait $1
}

# $1-保存的文件 
update_record() {
	loading_size=$(ls -l $1 2>/dev/null | awk '{print $5}')
	total_size=$(record_total_size $1)

	set_loading_size $1 $loading_size

	if [ $loading_size -eq $total_size ]; then
		set_down_state $1 $DOWNER_DONE
	fi
}

# $1-保存的文件 
check_record() {
	record_total=$(record_loading_total $2)
	if [ $record_total -gt $RECORD_TOTAL ]; then
		return 1
	fi

	state=$(record_down_state $1)
	if [ "$state" == "" ];then
		return 0
	fi

	return 1
}
