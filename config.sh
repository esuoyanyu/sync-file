# $1 段 $2 KEY $3 配置文件
value() {
	section=$1
	key=$2

	cat $3 2>/dev/null | grep -w "${key}" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 1
	fi

	cat $3 2>/dev/null | awk -F'=' '/\['$section'\]/ {find=1} find==1 && /'^$key='/ { print $2; exit}' | awk -F'#' '{print $1}' | awk '{print $1}'
}

# $1 同步文件夹列表
sync_dir_list() {
	echo "$1" | awk -F';' '{for (i=1; i<=NF; i++) { if (length($i) > 0) print $i}}'

}

# $1 配置文件 
set_env() {
	DOWN_DIR=$(value "global" DOWN_DIR $1)
	SYNC_DIR=$(value "global" SYNC_DIR $1)
	DOWNER=$(value "global" DOWER_TYPE $1)

	SYNC_DIR=$(sync_dir_list $SYNC_DIR)

	case "$DOWNER" in
	"scp")

		SERVICE_USER=$(value scp USER $1)
		SERVICE_HOST=$(value scp HOST $1)
		SERVICE_PORT=$(value scp PORT $1)

		export SERVICE_HOST
		export SERVICE_PORT
		export SERVICE_USER
	;;
	esac

	export DOWN_DIR
	export SYNC_DIR
	export DOWNER

	#echo $DOWNER
	#echo $SERVICE_USER
	#echo $SERVICE_HOST
	#echo $DOWN_DIR
}

#set_env $1
