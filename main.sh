#!/bin/bash

# Copyright [2023] [esuoyanyu]. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.
trap 'exited' SIGINT

work_dir=$(cd $(dirname $0); pwd)


pushd $work_dir

PID_LOCK=${2:-./sync-file.pid}
is_running() {
	if [ -f ${PID_LOCK} ]; then
		exit 1
	fi

	echo "$$" >$PID_LOCK
	return 0
}

is_running

source downloader.sh ${1:-./config}

exited() {
	if [ -f ${PID_LOCK} ]; then
		rm -f ${PID_LOCK}
	fi

	running=0

	exit 0
}

running=1
# $1-要同步的目录 $2-要保存的目录 $3 和子进程通信，获取进程状态
main() {
	while [ $running -eq 1 ]; do
		for dir in $1; do
			echo $dir
			sync_dir $dir $2 $3
		done
		#sleep 10	
		running=0
	done
	echo "task exit"

	exited
}


main "${4:-$SYNC_DIR}" "${5:-$DOWN_DIR}" "${3:-./task_state.downer}"

popd $work_dir

# crond /etc/cron.d
# m h dom mon dow user  command
#  30 22 * * * run this program
