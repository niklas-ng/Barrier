ITERATIONS=`seq 1 $ITER`
BENCHMARKS="SPECjbb2005"

trap "exit" INT

rm -f -r 2_specjbb_temp
mkdir -p 2_specjbb_temp
cd 2_specjbb_temp
mkdir -p logs
gcc ../dre.c -o dre.o -std=c99

mkdir "xml"
cp "$SPECJBB_DIR/xml/template-document.xml" xml
cp "$SPECJBB_DIR/xml/jbb-document.dtd" xml

echo -e "\n\n***** SPECjbb2005 1.07 Benchamrks *****"

PLOTFILE="$RES_DIR/$INDEX""_specjbb.txt"
PNG_OUTPUT="$RES_DIR/$INDEX""_specjbb.png"

mm=0;
cc=0;

echo "#Cores bops">$PLOTFILE

for real_core_num in $CORES; do
	echo -e "\n* Cores: $real_core_num"
	core_num=`echo "$real_core_num-1"|bc`
	line="$real_core_num"
	sum="scale=3;("
	for j in $ITERATIONS; do
		logname="logs/$real_core_num"_"SPECjbb"_"$j.txt"
		
		if [ "$1" = "test" ];
		then
			mm=`echo "$mm+1"|bc`;echo $mm>$logname
		else
			#creating properties file
			context=""
			context="$context\ninput.jvm_instances=1"
			context="$context\ninput.starting_number_warehouses=1"
			context="$context\ninput.increment_number_warehouses=1"
			eenndd=`echo "2*$real_core_num"|bc`
			context="$context\ninput.ending_number_warehouses=$eenndd"
			context="$context\ninput.expected_peak_warehouse =$real_core_num"  #usually should be commented
			#context-"$context\ninput.sequence_of_number_of_warehouses=1 8 16 20"
			context="$context\ninput.show_warehouse_detail=false"
			#description file
			context="$context\ninput.include_file=$SPECJBB_DIR/SPECjbb_config.props"
			context="$context\ninput.output_directory=`pwd`/SPECjbb_results"
			#don't change these parameters ;-)
			context="$context\ninput.suite=SPECjbb"
			context="$context\ninput.log_level=INFO"
			context="$context\ninput.deterministic_random_seed=false"
			context="$context\ninput.per_jvm_warehouse_rampup=3"			#must be 3
			context="$context\ninput.per_jvm_warehouse_rampdown=20"			#must be 20
			context="$context\ninput.ramp_up_seconds=2"						#must be 30
			context="$context\ninput.measurement_seconds=10"				#must be 240
			
			CP="$SPECJBB_DIR/jbb.jar:$SPECJBB_DIR/check.jar:$SPECJBB_DIR:$CLASSPATH"
			PROPERTIES_FILENAME="logs/$real_core_num"_"props"_"$j.props";
			
			echo -e "$context">$PROPERTIES_FILENAME
			
			IARG="-cp $CP $SPECJBB_MAIN_CLASS -propfile $PROPERTIES_FILENAME"
			eval taskset -c 0-$core_num $JAVA $IARG 2>&1 | tee $logname
		fi
		
		if [ "$?" != "0" ];
		then
			cat $logname
			exit
		fi	
		
		bops=`cat $logname|./dre.o`
		echo "*** $j) $bops bops"
		sum="$sum$bops"
		
		if [ "$j" != "$ITER" ];
		then
			sum="$sum+"
		else
			sum=`echo "$sum)/$ITER"|bc`
		fi
	done
	
	echo "** Average: $sum bops"
	line="$line $sum"
	
	echo $line>>$PLOTFILE
	cc=`echo "$cc+1"|bc`
	
done

col="1"
gpc="set style data linespoints;\
	set terminal png size 1000,800 ;\
	set output \"$PNG_OUTPUT\";\
	set title \"Throughput of SPECjbb2005 benchmarks for different number of cores\";\
	set xlabel \"Number of cores\";\
	set ylabel \"Score [SPECjbb2005 BOPS]\";\
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

echo -e "\nSPECjbb2005 benchamrk finished.\nSee:\n\t\"$PLOTFILE\"\n\t\"$PNG_OUTPUT\"\n"

cd ..