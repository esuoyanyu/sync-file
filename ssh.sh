#!/bin/bash

source base.sh

# $1-文件
# return 1 empty
# return 0 not empty
_is_empty_file() {
	ssh -p $SERVICE_PORT $SERVICE_USER@$SERVICE_HOST "$(declare -f __is_empty_file); __is_empty_file $1"
	return $?
}

# $1-目录
# return 1 empty
# return 0 not empty
_is_empty_dir() {
	ssh -p $SERVICE_PORT $SERVICE_USER@$SERVICE_HOST "$(declare -f __is_empty_dir); __is_empty_dir $1"
	return $?
}

# $1-要删除的文件或目录
_rm() {
	#ssh -p $SERVICE_PORT $SERVICE_USER@$SERVICE_HOST "$(declare -f __rm); __rm $1"
	return 0 #$?
}

# $1 文件
_is_file() {
	ssh -p $SERVICE_PORT $SERVICE_USER@$SERVICE_HOST "$(declare -f __is_file); __is_file $1;"
	return $?
}

# $1 文件
_is_dir() {
	ssh -p $SERVICE_PORT $SERVICE_USER@$SERVICE_HOST "$(declare -f __is_dir); __is_dir $1"
	return $?
}

# $1 目录
_file_list() {
	ssh -p $SERVICE_PORT $SERVICE_USER@$SERVICE_HOST "$(declare -f __file_list); __file_list $1;"
	return $?
}

# $1-将要下载的文件 $2保存目录
_download_file() {
	file=$1
	dir=${2:-./}

	scp -P ${SERVICE_PORT} ${SERVICE_USER}@${SERVICE_HOST}:"$file" $dir #2>/dev/null
	if [ $? -eq 0 ]; then
		_rm $1
		return 0
	fi

	return 1
}

# $1-将要下载的文件 $2保存目录
_download_dir() {
	dir=$1
	save_dir=${2:-./}

	scp -P ${SERVICE_PORT} -r ${SERVICE_USER}@${SERVICE_HOST}:"$dir" $save_dir #2>/dev/null
	if [ $? -eq 0 ]; then
		_rm $1
		return 0
	fi

	return 1
}
