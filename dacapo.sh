BENCHMARKS=`$JAVA -jar "$DACAPO_JAR_FILE" -l`
#BENCHMARKS="avrora fop h2 luindex xalan"
ITERATIONS=`seq 1 $ITER`

trap "exit" INT

rm -f -r 1_dacapo_temp
mkdir -p 1_dacapo_temp
cd 1_dacapo_temp
mkdir -p logs
gcc ../dre.c -o dre.o -std=c99

echo -e "\n\n***** Dacapo 9.12 Benchamrks *****"

PLOTFILE="$RES_DIR/$INDEX""_dacapo.txt"
PNG_OUTPUT="$RES_DIR/$INDEX""_dacapo.png"

mm=0;
cc=0;
#BENCHMARKS="xalan"
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
				IARG="-jar \"$DACAPO_JAR_FILE\" $bench $DACAPO_ARGS -t $real_core_num"
				eval taskset -c 0-$core_num $JAVA $IARG 2>&1 | tee $logname
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
	set title \"Execution time of Dacapo-9.12 benchmarks for different number of cores\";\
	set xlabel \"Number of cores\";\
	set ylabel \"Execution time [ms]\";\
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

echo -e "\nDacapo benchamrk finished.\nSee:\n\t\"$PLOTFILE\"\n\t\"$PNG_OUTPUT\"\n"

cd ..