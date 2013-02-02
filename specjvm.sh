trap "exit" INT

rm -f -r 3_specjvm_temp
mkdir -p 3_specjvm_temp
cd 3_specjvm_temp
mkdir -p logs
gcc ../dre.c -o dre.o -std=c99

SJ_EXE="-Dspecjvm.home.dir=$SPECJVM_DIR -jar $SPECJVM_JAR_FILE"
SJ_EXE="-Dspecjvm.result.dir=`pwd`  $SJ_EXE"
SJ_EXE="-Xbootclasspath/p:$SPECJVM_DIR/lib/javac.jar $SJ_EXE"

WARMUP_TIME="120s"		#120 by default
ITERATION_TIME="240s"	#240 by default
ITEARATIONS_NUMBER="1"	#1 by default
JVM_ARGS=""				#required for startup benchmarks

#with startup benchmarks
BENCHMARKS=`$JAVA $SJ_EXE -help|grep Benchmarks|tail -n1|cut -f2-39 -d' '`
#without startup bnechmarks
BENCHMARKS=`$JAVA $SJ_EXE -help|grep Benchmarks|tail -n1|cut -f19-39 -d' '`
#for test 
#BENCHMARKS="crypto.aes"
#BENCHMARKS=" scimark.sor.large scimark.fft.large  scimark.sparse.large  scimark.sor.small scimark.sparse.small scimark.monte_carlo"

#list of all benchmarks:
# compiler.compiler compiler.sunflow compress crypto.aes crypto.rsa crypto.signverify
# derby mpegaudio scimark.fft.large  scimark.lu.large  scimark.sor.large  scimark.sparse.large
# scimark.fft.small scimark.lu.small  scimark.sor.small scimark.sparse.small scimark.monte_carlo
# serial sunflow xml.transform  xml.validation


ITERATIONS=`seq 1 $ITER`

echo -e "\n\n***** SPECjvm2008 1.01 Benchamrks *****"
for i in $BENCHMARKS ;
do
	echo "#" $i
done

PLOTFILE="$RES_DIR/$INDEX""_specjvm.txt"
PNG_OUTPUT="$RES_DIR/$INDEX""_specjvm.png"

mm=0;
cc=0;

echo "#Cores $BENCHMARKS">$PLOTFILE

for real_core_num in $CORES; do
	echo -e "\n* Cores: $real_core_num"
	core_num=`echo "$real_core_num-1"|bc`
	line="$real_core_num";

	for bench in $BENCHMARKS; do
		echo -e "\n** Benchmark \"$bench\" with $real_core_num-cores"
		sum="scale=3;("
		
		for j in $ITERATIONS; do
			logname="logs/$real_core_num"_"$bench"_"$j.txt"
			
			if [ "$1" == "test" ];
			then
				mm=`echo "$mm+1"|bc`;echo $mm>$logname
			else
				SJ_ARGS="-ikv --base $bench --base -bt $real_core_num"
				SJ_ARGS="$SJ_ARGS -wt $WARMUP_TIME "   #warmup time, 120 by default
				SJ_ARGS="$SJ_ARGS -it $ITERATION_TIME "   #iteration time, 240 
				SJ_ARGS="$SJ_ARGS -i $ITEARATIONS_NUMBER "    #number of iterations
				#SJ_ARGS="$SJ_ARGS -ja $JVM_ARGS "    #jvm args required for startup.* benchmarks

				eval taskset -c 0-$core_num $JAVA $SJ_EXE $SJ_ARGS 2>&1 | tee $logname
			fi
			
			if [ "$?" != "0" ];
				then
					cat $logname
					exit
			fi	
			
			time=`cat $logname|./dre.o`
			echo "*** $j) $time ms"
			sum="$sum$time"
			
			if [ "$j" != "$ITER" ];
				then
				sum="$sum+"
				else
				sum=`echo "$sum)/$ITER"|bc`
			fi
		done
		
		echo "** Average: $sum ms"
		line="$line $sum"
		
	done
	echo $line>>$PLOTFILE
	cc=`echo "$cc+1"|bc`
done

col="1"
gpc="set style data linespoints;\
	set terminal png size 1000,1000 ;\
	set output \"$PNG_OUTPUT\";\
	set title \"Throughput time of SPECjvm2008 benchmarks for different number of cores\";\
	set xlabel \"Number of cores\";\
	set ylabel \"Throughput [SPECjvm2008 base ops/m]\";\
	set key rmargin;\
	plot [-1:$cc][] "
for bench in $BENCHMARKS; do
	col=`echo "$col+1"|bc`
	if [ "$col" != "2" ]; 
	then 
		gpc="$gpc , "
	fi
		
	gpc="$gpc \"$PLOTFILE\" u $col:xtic(1) t \"$bench\""
done

echo $gpc>gp_command
echo $gpc|gnuplot

echo -e "\nSPECjvm2008 benchamrks finished.\nSee:\n\t\"$PLOTFILE\"\n\t\"$PNG_OUTPUT\"\n"

cd ..