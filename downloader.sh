# Copyright [2023] [esuoyanyu]. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

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

echo "$DOWNER"

# $1-下载的文件 $2-保存的路径
donwloader() {
	_is_file $1
	file_or_dir=$?

	_is_empty_file $1
	is_empty=$?
	if [ $file_or_dir -eq 1 ]; then
		if [ $is_empty -eq 0 ]; then
			echo "download file start $1"
			_download_file $1 $2
			return 0
		else
			_rm $1
			return 1
		fi
	fi

	_is_dir $1
	file_or_dir=$?

	_is_empty_dir $1
	is_empty=$?
	if [ $file_or_dir -eq 1 ]; then
		if [ $is_empty -eq 0 ]; then
			echo "download dir start $1"
			_download_dir $1 $2
			return 0
		else
			_rm $1
			return 1
		fi
	fi

	return 1
}
