source config.sh

set_env $1

case "$DOWNER" in
	"scp")
		source ssh.sh
	;;
	*)
		echo "downloader not support"
	;;
esac

echo $DOWNER

# $1-下载的文件 $2-保存的路径
donwloader() {
	_is_file $1
	file_or_dir=$?

	_is_empty_file $1
	is_empty=$?
	if [ $file_or_dir -eq 1 -a $is_empty -eq 1 ]; then
		echo "download file start $1"
		_download_file $1 $2
		echo "downlaod file done"
		return 0
	fi

	echo "sssssssssssssssssssss"

	_is_dir $1
	file_or_dir=$?

	_is_empty_dir $1
	is_empty=$?
	if [ $file_or_dir -eq 1 -a $is_empty -eq 1 ]; then
		echo "download dir start $1"
		_download_dir $1 $2
		echo "downlaod dir done"
		return 0
	fi

	return 1
}

# $1 要同步的目录 $2 要保存的目录 $3 和父进程通信 file
sync_dir() {
	#1. get file list
	file_list=$(_file_list $1)
	if [ "$file_list" == "" ]; then
		return 1
	fi

	echo "file_list = $file_list"

	for item in $file_list; do
		donwloader $item $2
	done

	#"$1 $pid $?" >>$3
	return 0
}
