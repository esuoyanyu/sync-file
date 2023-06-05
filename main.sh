#!/bin/bash

# Copyright [2023] [esuoyanyu]. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

work_dir=$(cd $(dirname $0); pwd)

pushd $work_dir

trap 'exited' SIGINT

source message.sh
source downloader.sh ${1:$work_dir/config}

PID_LOCK=${2:$work_dir/sync-file.pid}
exited() {
	if [ -f ${PID_LOCK} ]; then
		rm -f ${PID_LOCK}
	fi

	running=0

	exit 0
}

is_running() {
	if [ -f ${PID_LOCK} ]; then
		exit 1
	fi

	echo "$$" >$PID_LOCK
	return 0
}

running=1
# $1-要同步的目录 $2-要保存的目录 $3 保存进程状态
main() {
	is_running
	create_task $$

	while [ $running -eq 1 ]; do
		for dir in $1; do
			check_downloader $dir $total
		 	if [ $? -eq 0 ]; then
				create_downloader $1 $2 &
			fi
		done

		total=$(echo $1 | wc -l)
		state=$(update_task $$ $total "downer.$$.log")
		if [ "$state" == "done" ]; then
			running=0
		fi
	done

	destory_task $1

	echo "task exit"

	exited
}

main "${4:-$SYNC_DIR}" "${5:-$DOWN_DIR}" "${3:-$work_dir/task_state.downer}"

popd

# crond /etc/cron.d
# m h dom mon dow user  command
#  30 22 * * * run this program
