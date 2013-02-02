#general settings
export CORES="8 16 48"
JAVA="java"
JAVA="$JAVA -Xms100G -Xmx200G -XX:+UseConcMarkSweepGC" #-XX:+UseSerialGC, -XX:+UseParallelGC
JAVA="$JAVA -XX:+PrintGC" #-XX:+PrintGCDetails -XX:+PrintGCTimeStamps
export JAVA
export ITER="1"
export RES_DIR=`pwd`/results

#dacapo settings
export DACAPO_JAR_FILE="`pwd`/dacapo-9.12-bach.jar"
export DACAPO_ARGS="" #"--no-pre-iteration-gc -n 10" # -C" #allow benchamrk times to converge

#specjbb settings
export SPECJBB_DIR="`pwd`/SPECjbb2005_1.07"
export SPECJBB_MAIN_CLASS="spec.jbb.JBBmain"

#specjvm settings
export SPECJVM_DIR="`pwd`/SPECjvm2008"
export SPECJVM_JAR_FILE="$SPECJVM_DIR/SPECjvm2008.jar"


if [ "$1" = "" ];
then
	echo -e "\nUse: \"test.sh  [dacapo] [specjbb] [specjvm] [test] [clean]\"\n"
	exit -1
fi

INDEX_FILE="$RES_DIR/.index"

trap "exit" INT
args=$*

if [ "`echo $args|grep clean`" != "" ];
then
	rm -f -r 1_dacapo_temp 2_specjbb_temp 3_specjvm_temp scratch results
	exit
fi

args_names="test dacapo specjbb specjvm"
IFS=' ' read -a names <<< "${args_names}"
for i in `seq 0 3`;
	do
	aa=${names[$i]}
	ee=`echo $args|grep $aa`
	if [ "$ee" = "" ]
		then
		eval "$aa""_arg"=""
		else
		eval "$aa""_arg"=$aa
	fi;
done

#echo $test_arg $dacapo_arg $specjbb_arg $specjvm_arg

if [ -e $RES_DIR ];
then
	if [ -e $INDEX_FILE ];
	then
		INDEX=`cat $INDEX_FILE`
		INDEX=`echo "$INDEX+1"|bc`
	else
		INDEX="0"
	fi
else
	mkdir -p $RES_DIR
	INDEX="0"
fi

echo "$INDEX">"$INDEX_FILE"
export INDEX


if [ "$dacapo_arg" != "" ];
then
	if [ -e $DACAPO_JAR_FILE ];
	then
		echo -e "\nDacapo jar file: \"$DACAPO_JAR_FILE\"."
	else
		echo -e "\nDacapo jar file \"$DACAPO_JAR_FILE\" doesn't exist.\n"
		exit -2
	fi
	
	./dacapo.sh $test_arg
fi

if [ "$specjbb_arg" != "" ];
then
	if [ -e $SPECJBB_DIR ];
	then
		echo -e"\nSPECjbb2005 directory: \"$SPECJBB_DIR\"."
	else
		echo -e "\nSPECjbb2005 directory \"$SPECJBB_DIR\" doesn't exist.\n"
		exit -3
	fi
	
	./specjbb.sh $test_arg
fi

if [ "$specjvm_arg" != "" ];
then
	if [ -e $SPECJVM_JAR_FILE ];
	then
		echo -e "\nSPECjvm2008 jar file: \"$SPECJVM_JAR_FILE\"."
	else
		echo -e "\nSPECjvm2008 jar file \"$SPECJVM_JAR_FILE\" doesn't exist.\n"
		exit -4
	fi
	
	./specjvm.sh $test_arg
fi