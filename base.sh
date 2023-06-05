# $1-文件
# return 1 empty
# return 0 not empty
__is_empty_file() {
	if [ -s "$1" ]; then
		return 0
	else
		return 1
	fi
}

# $1-目录
# return 1 empty
# return 0 not empty
__is_empty_dir() {
	total=$(ls -l $1 2>/dev/null | wc -l)
	if [ $total -eq 1 ]; then
		return 1
	else
		return 0
	fi
}

# $1 要删除的文件或目录
__rm() {
	if [ -f "$1" ]; then
		rm -f $1 2>/dev/null;
	else
		rm -rf $1 2>/dev/null;
	fi
}

# $1 目录
__file_list() {
	list="$(ls ${1} -lA 2>/dev/null | awk '{ if(NF >= 9) {dir=$9; for(i=10; i <= NF; i++) { dir=(dir" "$i); } print dir}}')"
	IFS=$'\n'
	for curr_dir in ${list}; do
		dir_or_file=${1}/${curr_dir}
		if [ -d  ${dir_or_file} -a "$(ls ${dir_or_file} 2>/dev/null)" != "" ]; then
			__file_list ${dir_or_file}
		else
			dir_or_file=$(echo "$dir_or_file" | sed "s#(#\\\(#g")
			dir_or_file=$(echo "$dir_or_file" | sed "s#)#\\\)#g")
			echo "${dir_or_file}"
		fi
	done
}

# $1 文件
__is_file() {
	if [ -f "$1" ]; then
		return 1
	fi

	return 0
}

# $1 文件
__is_dir() {
	if [ -d "$1" ]; then
		return 1;
	fi

	return 0
}
