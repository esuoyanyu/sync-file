#!/bin/bash

source downloader.sh ${3:-./test/config.test}

PID_LOCK=./sync-file.pid
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
# $1-要同步的目录 $2-要保存的目录 $3 和子进程通信，获取进程状态
main() {
	is_running
	while [ $running -eq 1 ]; do
		for dir in $1; do
			echo $dir
			sync_dir $dir $2 $3
		done
		sleep 10	
	done
}

trap 'exited' SIGINT

main ${1:-$SYNC_DIR} ${2:-$DOWN_DIR} ${4:-./task_state.downer}

# crond /etc/cron.d
# m h dom mon dow user  command
#  30 22 * * * run this program