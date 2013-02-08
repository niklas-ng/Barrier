BENCHMARKS="ParallelGC ConcMarkSweepGC"
ITERATIONS=`seq 1 $ITER`

trap "exit" INT

rm -f -r 4_listbench_temp
mkdir -p 4_listbench_temp
cd 4_listbench_temp
mkdir -p logs
gcc ../dre.c -o dre.o -std=c99

echo -e "\n\n***** List Benchamrk *****"

mm=0;

PNG_OUTPUT="$RES_DIR/$INDEX""_listbench.png"
	
gpc="set style data linespoints;\
	set terminal png size 2000,600 ;\
	set output \"$PNG_OUTPUT\";
	set multiplot;"
	
origin="0"

for size in $LISTBENCH_ARRAY_SIZES; do

	PLOTFILE="$RES_DIR/$INDEX""_""$size""_listbench.txt"
	
	cc=0;
	
	echo "#Cores $BENCHMARKS">$PLOTFILE


	for real_core_num in $CORES; do
		echo -e "\n* Cores: $real_core_num"
		core_num=`echo "$real_core_num-1"|bc`
		line="$real_core_num";

		for bench in $BENCHMARKS; do
			echo -e "\n** Benchmark \"$bench\" for size \"$size""B\" with $real_core_num-cores"
			sum="scale=3;("
			
			for j in $ITERATIONS; do
				logname="logs/$real_core_num"_"$bench"_"$j.txt"
				
				if [ "$1" == "test" ];
					then
					mm=`echo "$mm+1"|bc`;echo -e "$mm\n1$mm">$logname
					else
					IARG="-XX:+Use$bench \"$LISTBENCH_FILE\" $size $LISTBENCH_NEXT_ARGS $real_core_num"
					eval taskset -c 0-$core_num $JAVA  "-XX:+UseNUMA"  -cp $LISTBENCH_DIR:$CLASSPATH $IARG 2>&1 | tee $logname
				fi
				
				if [ "$?" != "0" ];
					then
						cat $logname
						exit
				fi	
				
				time=`cat $logname|tail -n2|head -n1|./dre.o`
				echo "*** $j) $time ns"
				sum="$sum$time"
				
				if [ "$j" != "$ITER" ];
					then
					sum="$sum+"
					else
					sum=`echo "$sum)/$ITER"|bc`
				fi
			done
			
			echo "** Average: $sum ns"
			line="$line $sum"
			
		done
		echo $line>>$PLOTFILE
		cc=`echo "$cc+1"|bc`
	done

	col="1"
	echo `echo "$origin+.4==1"|bc`
	if [ `echo "$origin+.4==1"|bc` = "1" ];
	then 
		key="rmargin";
		length="0.4"
	else
		key="off";
		length="0.3";
	fi
	gpc="$gpc set size $length,1;\
		set origin $origin,0.0;\
		set title \"Memory access time for size $size""B  \";\
		set xlabel \"Number of cores\";\
		set ylabel \"Memory access time [ns]\";
		set key $key;\
		plot [-1:$cc][] "
	origin=`echo "$origin+.3"|bc`
	for bench in $BENCHMARKS; do
		col=`echo "$col+1"|bc`
		if [ "$col" != "2" ]; 
			then 
				gpc="$gpc , "
		fi
			
		gpc="$gpc \"$PLOTFILE\" u $col:xtic(1) t \"$bench\""
	done
	
	gpc="$gpc ;"

done

echo $gpc>gp_command
echo $gpc|gnuplot


echo -e "\nList Benchmark finished.\nSee:\n\t\"$PLOTFILE\"\n\t\"$PNG_OUTPUT\"\n"

cd ..