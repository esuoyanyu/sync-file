#!/bin/bash

REMOTE_USER=chy
REMOTE_HOST=esuoyanyu.com
REMOTE_PORT=22
DOWNLOAD_DIR=/home/media/cache

LOCAL_USER=media
LOCAL_HOST=esuoyanyu.com
LOCAL_PORT=9000
UPLOAD_DIR=cache

# $1 要查找的目录
_get_list_ssh() {
	#echo "test s"
	#list=$(ssh -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "$(typeset -f); echo \"get_list_start\"; _get_list_local $1; echo \"get_list_end\"")
	#IFS=$'##'
	#list=$(ssh -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "$(typeset -f); _get_list_local $1;")
	ssh -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "$(typeset -f); _get_list_local $1;"
	#echo $list

	#echo "$(echo ${list} | sed -n "/get_list_start/,/get_list_end/p")"
}

# $1 要查找的目录
_get_list_local() {

	list="$(ls ${1} -lA 2>/dev/null | awk '{ if(NF >= 9) {dir=$9; for(i=10; i <= NF; i++) { dir=(dir" "$i); } print dir}}')"
	IFS=$'\n'
	for curr_dir in ${list}; do
		dir_or_file=${1}/${curr_dir}
		if [ -d  ${dir_or_file} -a "$(ls ${dir_or_file} 2>/dev/null)" != "" ]; then
			_get_list_local ${dir_or_file}
		else
			echo "${dir_or_file}"
		fi
	done
}

# $1 type $2 要查找的目录
get_list() {
	IFS=$'\n'
	case "$1" in
	"ssh")
		_get_list_ssh $2
	;;
	"local")
		_get_list_loacl $2
	;;
	*)
		echo "get_list type error"
	;;
	esac
}

# $1-要删除的文件或目录
_rm_ssh() {
	ssh ${REMOTE_USER}@${REMOTE_HOST} "if [ -f $1 ]; then rm -f $1; else rm -rf $1; fi"
}

_rm_local() {
	if [ -f $1 ]; then
		rm -f $1
	else
		rm -rf $1
	fi
}

_rm() {
	case "$1" in
	"ssh")
		_rm_ssh $2
	;;
	"local")
		_rm_local $2
	;;
	*)
		echo "_rm type error"
	;;
	esac
}

# $1 文件
_is_file_and_no_empty_ssh() {
	ret=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "if [ -f $1 -a -s $1 ]; then echo '0'; elif [ -f $1 -a ! -s $1 ]; then echo '1'; else echo '2'; fi")

	return $ret
}

_is_dir_ssh() {

	ret=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "if [ -d $1 ]; then echo 0; else echo 1; fi")

	return $ret
}

_is_file_and_no_empty_local() {
	if [ -f $1 -a -s $1 ]; then
		return 0
	elif [ -f $1 -a ! -s $1 ]; then
		return 1
	else
		return 2
	fi
}

_is_dir_local() {
	if [ -d $1 ]; then
		return 0
	else
		return 1
	fi
}

# $1 type $2 文件
_is_file_and_no_empty() {
	case "$1" in
	"ssh")
		_is_file_and_no_empty_ssh $2
		return $?
	;;
	"local")
		_is_file_and_no_empty_local $2
		return $?
	;;
	*)
		echo "_is_file_and_no_empty type error"
	;;
	esac
}

# $1 type $2 目录
_is_dir() {
	case "$1" in
	"ssh")
		_is_dir_ssh $2
		return $?
	;;
	"local")
		_is_dir_local $2
		return $?
	;;
	*)
		echo "_is_dir type error"
	;;
	esac
}


# $1 type $2 将要下载的文件
_download_form_remote() {
	ret=1

	_is_file_and_no_empty $1 $2
	ret=$?
	if [ ${ret} -eq 0 ]; then
		file_path=$(dirname ${2})
		if [ ! -d ${file_path} ]; then
			mkdir -p ${DOWNLOAD_DIR}/${file_path}
		fi

		scp -P ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}:$2 ${DOWNLOAD_DIR}/${file_path} #2>/dev/null
		if [ $? -eq 0 ]; then
			_rm_ssh $2
			return 0
		else
			return 1
		fi
	elif [ ${ret} -eq 1 ]; then
		echo "$2 is empty"
		_rm_ssh $2
		return 0
	fi

	_is_dir $1 $2
	ret=$?
	if [ ${ret} -eq 0 ]; then
		scp -P ${REMOTE_PORT} -r ${REMOTE_USER}@${REMOTE_HOST}:$2 ${DOWNLOAD_DIR} 2>/dev/null
		if [ $? -eq 0 ]; then
			_rm_ssh $2
			return 0

		else
			return 1
		fi
	elif [ ${ret} -eq 1 ]; then
		echo "$2 dir is empty"
		_rm_ssh $2
		return 2
	fi
}



# $1 将要获取的文件
_upload_to_local() {
	ret=1

	_is_file_no_empty $1 $2
	ret=$?
	if [ ${ret} -eq 0 ]; then
		echo "upload file ${2}"
		file_path=$(dirname ${2})
		ssh -p ${LOCAL_PORT} ${LOCAL_USER}@${LOCAL_HOST} "if [ ! -d ~/${UPLOAD_DIR}/${2} ]; then mkdir -p ~/${UPLOAD_DIR}/${2} fi" 2>/dev/null
		if [ $? -eq 0 ]; then
			scp -P ${LOCAL_PORT} ${2} ${LOCAL_USER}@${LOCAL_HOST}:~/${UPLOAD_DIR}/${2} 2>/dev/null
			if [ $? -eq 0 ]; then
				_rm_local ${2}
				return 0
			fi
		fi
	elif [ ${ret} -eq 1 ]; then
		echo "$2 file is empty"
		_rm_local $2
		return 1
	fi

	_is_dir $1 $2
	ret=$?
	if [ ${ret} -eq 0 ]; then
		scp -P ${LOCAL_PORT} -r ${2} ${LOCAL_USER}@${LOCAL_HOST}:~/${UPLOAD_DIR} 2>/dev/null
		if [ $? -eq 0 ]; then
			_rm_local $2
			return 0

		else
			return 1
		fi
	elif [ ${ret} -eq 1 ]; then
		echo "$2 dir is empty"
		_rm_local $2
		return 2
	fi

	return "${ret}"
}

# $1 type $2 file
_upload() {
	case "$1" in
	"ssh")
		#echo $2
		_download_form_remote $1 $2
	;;
	"local")
		_upload_to_local $1 $2
	;;
	*)
		echo "_upload type error"
	;;
	esac
}

# $1 tyep $2 将要上传的文件列表
upload() {
	ret=0
	list=$2
	#echo $2
	IFS=$'\n'
	for file in ${list}; do
		#echo $file
		#if [ -f ${file} -a -s "${file}" ]; then
		_upload $1 ${file}
		#echo "upload end"
	done

	return "${ret}"
}

#list=$(get_list ./test)

#IFS=$"\n"
#echo ${list}

#upload "${list}"

LOCK_FILE=/home/media/bin/upload.lock
running() {
	if [ -f ${LOCK_FILE} ]; then
		return 1
	else
		echo "$$" > ${LOCK_FILE}
		return 0
	fi
}

exited() {
	if [ -f ${LOCK_FILE} ]; then
		rm -f ${LOCK_FILE}
	fi

	exit 0
}

# $1-要同步的目录
main() {

	trap 'exited' SIGINT

	running
	if [ $? -eq 1 ]; then
		echo "is running"
		exit 1
	fi

	while true; do
		list=$(get_list "ssh" $1)
		#IFS=$'\n'
		#echo $list
		if [ "${list}" == "" ]; then
			break;
		fi
		#echo "ssssss"
		upload "ssh" "${list}"
		#echo "ssiiiissss"

		sleep 10
	done

	exited
}

main /home/chy/ut/ok

#_get_list_ssh /home/chy/ut/ok
