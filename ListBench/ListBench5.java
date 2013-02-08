import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

class ListBench5{
	private long getArgValue(String args[],int index, String def){
		long value;
		String val_str=def;
		if(args.length>index)
			val_str=args[index];
		val_str=val_str.toLowerCase();
		
		int i;
		for(i=0;i<val_str.length();i++){
			char a=val_str.charAt(i);
			if((a>='A' && a<='Z') || (a>='a' && a <='z'))
				break;
		}
		
		if(i==val_str.length())
			value=Integer.parseInt(val_str);
		else{
			value=Integer.parseInt(val_str.substring(0,i));
			switch(val_str.charAt(i)){
				case 'g':
					value*=1024;
					
				case 'm':
					value*=1024;
				
				case 'k':
					value*=1024;
			}
		}
		
		return value;
	}
	static public void main(String args[]){
	
		new ListBench5(args);
		
		System.exit(0);
	}
	
	private long size;
	private int minor;
	private int iters;
	private int threads_num;
	private long substitutions;
	private char [][] firstarray;
	private volatile double [] results;
	private volatile int results_index;
	private volatile double [] dur;
	private volatile AtomicInteger aint;
	private volatile int indexes[];
	
	void readArgs(String args[]){
		
		size=getArgValue(args,0,"40K");
		System.out.println("Major Size: "+size);
		
		minor=(int)getArgValue(args,1,"128");
		System.out.println("Minor Size: "+minor);
		
		if((long)Integer.MAX_VALUE < size/minor){
			System.out.println("Major/Minor is too large.");
			System.exit(-1);
		}
		
		iters=(int)getArgValue(args,2,"10");
		System.out.println("Test Iterations: "+iters);
		
		substitutions=getArgValue(args,3,"10M");
		System.out.println("Number of Substitutions: "+substitutions);
		
		threads_num=(int)getArgValue(args,4,"2");
		System.out.println("Number of Threads: "+threads_num);
		
		return;
	}
	
	public ListBench5(String args[]){
		
		readArgs(args);
	
		//firstarray=new char[(int)(size/minor)][];
		
// 		for(int i=0;i<(int)(size/minor);i++){
// 			firstarray[i]=new char[minor];
// 			for(int j=0;j<minor;j++)
// 				firstarray[i][j]=(char)(j+i);
// 		}
// 		
		results=new double[iters+1];
		results_index=0;
		
		indexes=createLocalIndexes((int)((int)(size/minor)/threads_num));
		
		class MyThread extends Thread{
			int index;
			double [] duration;
			int tn;
			int localindexes[];
			char [][] array;
			
			public MyThread(int in, double[] dur,int thl){
				index=in;
				duration=dur;
				tn=dur.length;
				int thlen=thl;
				array=new char[thlen][];
				for(int k=0;k<thlen;k++){
					array[k]=new char[minor];
					for(int i=0;i<minor;i++)
						array[k][i]=(char)(i+k);
				}
				//System.out.println(thl);
					
			}
			
			public void run(){
			
				int len=array.length;
				int mylen=len;//tn;
				int arr_offset=0;//mylen*index;
				
				if(indexes==null)
					localindexes=createLocalIndexes(mylen);
				else{
					localindexes=new int[indexes.length];
					for(int i=0;i<localindexes.length;i++)
						localindexes[i]=indexes[i];
				}
				
				int lilen=localindexes.length;
				
				aint.incrementAndGet();
				
				System.err.println("Thread "+index+": I'm ready");System.err.flush();
				
				while(aint.get()<=tn)
					;
			
				long start=System.nanoTime();
				
				char [][] myarray=new char[mylen][];
				for(int i=0;i<mylen;i++)
					myarray[i]=array[arr_offset+i];
				
				Random rand=new Random();
				char temp[];
				//String s="";
				int li=0;
				int dist=0;
				int mm=0;
				for(long i=0;i<substitutions;i++){
					//int j=dist+mm++;
					//int k=dist+mm++;
					//mm%=(mylen-dist);
					
					int j=localindexes[(++li)%lilen];
					int k=localindexes[(++li)%lilen];
					li=li%(lilen);
					
					temp=myarray[j];
					myarray[j]=array[arr_offset+k];
					array[arr_offset+k]=temp;
					//s=s+","+(arr_offset+k);
				}
				
				long dur=System.nanoTime()-start;
				duration[index]=((double)dur)/substitutions;
				
				System.out.println("Thread "+index+" Access Time: "+duration[index]+"ns");
				//System.out.println("Indexes accessed by thread "+index+" are: "+s);
				System.out.flush();
				//System.out.println("Accessing "+arr_offset+" - "+(arr_offset+mylen-1));
				
				
							
				return;
			}
		}
		
		for(int i=0;i<=iters;i++){
			System.out.println();
			System.gc();
			System.out.println("============================================");
			System.out.println("Iteration: "+i);
			
			Thread[] threads=new Thread[threads_num];
			dur=new double[threads_num];
			
			aint=new AtomicInteger(0);
			//int thlen= firstarray.length/threads_num;
			
			for(int j=0;j<threads_num;j++){
				
				threads[j]=new MyThread(j,dur,(int)(size/(minor*threads_num)));
				threads[j].start();
			}
			
			while(aint.get()!=threads_num)
				;
			
			try{
				Thread.currentThread().sleep(100);
			}catch(Exception e){}
				
			System.err.println("Main: All ready");System.err.flush();
				
			aint.incrementAndGet();
			
			try{
				for(int j=0;j<threads_num;j++)
					threads[j].join();
			}
			catch(Exception e){
				e.printStackTrace();
			}
			
			double duration=dur[0];
			for(int j=1;j<threads_num;j++)
				duration+=dur[j];
				
			duration/=threads_num;
			duration/=threads_num;
			
			System.out.println("Access Time: "+duration+"ns");
			
			results[results_index++]=duration;
		}
		
		
		double mean=0;
		int count=0;
		for(int i=iters/2;i<=iters;i++){
			mean+=results[i];
			count++;
		}
		mean=mean/count;
		
		double stdev=0;
		for(int i=iters/2;i<=iters;i++){
			double t=mean-results[i];
			stdev+=t*t;
		}
		stdev=stdev/count;
		double stdev2=Math.sqrt(stdev);
		
		
		System.out.println("\n\n============================================");
		System.out.println("Average: "+mean+"ns");
		System.out.println("Standard Deviation: "+stdev2+"ns");	
		
		return;
	}
	
	int[] createLocalIndexes(int len){
		Random r=new Random();
		int arr[]=new int[100*1000];
		for(int i=0;i<arr.length;i++)
			arr[i]=r.nextInt(len);
		return arr;
	}
}