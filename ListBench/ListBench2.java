import java.util.Random;
import java.util.concurrent.CyclicBarrier;

class ListBench2{
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
	
		new ListBench2(args);
		
		System.exit(0);
	}
	
	private long size;
	private int minor;
	private int iters;
	private int threads_num;
	private long substitutions;
	private char [][] array;
	private volatile long [] results;
	private volatile int results_index;
	private volatile long[] dur;
	
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
	
	public ListBench2(String args[]){
		
		readArgs(args);
	
		array=new char[(int)(size/minor)][];
		
		for(int i=0;i<(int)(size/minor);i++){
			array[i]=new char[minor];
			for(int j=0;j<minor;j++)
				array[i][j]=(char)(j+i);
		}
		
		results=new long[iters+1];
		results_index=0;
		
		class MyThread extends Thread{
			int index;
			long [] duration;
			CyclicBarrier cb;
			int tn;
			
			public MyThread(int in, long[] dur, CyclicBarrier barr){
				index=in;
				duration=dur;
				cb=barr;
				tn=dur.length;
			}
			
			public void run(){
				try{
					cb.await();
				
					long start=System.nanoTime();
					
					int len=array.length;
					int mylen=len/tn;
					int arr_offset=mylen*index;
					
					char [][] myarray=new char[mylen][];
					for(int i=0;i<mylen;i++)
						myarray[i]=array[arr_offset+i];
					
					Random rand=new Random();
					char temp[];
					for(long i=0;i<substitutions;i++){
						int j=((int)(2*i))%mylen;
						int k=((int)(2*i+1))%mylen;
						//int j=rand.nextInt(mylen);
						//int k=rand.nextInt(mylen);
						
						temp=myarray[j];
						myarray[j]=array[arr_offset+k];
						array[arr_offset+k]=temp;
					}
					
					long dur=System.nanoTime()-start;
					
					System.out.println("Thread "+index+" Execution Time: "+(dur/(1000000))+"ms");
					//System.out.println("Accessing "+arr_offset+" - "+(arr_offset+mylen-1));
					
					duration[index]=dur;
				}
				catch(InterruptedException e){
					e.printStackTrace();
					//System.exit(-1);
				}
				catch(java.util.concurrent.BrokenBarrierException e){
					e.printStackTrace();
					//System.exit(-1);
					sd
				}
				
				return;
			}
		}
		
		CyclicBarrier barr=new CyclicBarrier(threads_num);
		for(int i=0;i<=iters;i++){
			System.out.println();
			System.gc();
			System.out.println("============================================");
			System.out.println("Iteration: "+i);
			
			Thread[] threads=new Thread[threads_num];
			dur=new long[threads_num];
			
			
			for(int j=0;j<threads_num;j++){
				threads[j]=new MyThread(j,dur,barr);
				threads[j].start();
			}
			
			
			try{
				for(int j=0;j<threads_num;j++)
					threads[j].join();
			}
			catch(Exception e){
				e.printStackTrace();
			}
			
			long duration=dur[0];
			for(int j=1;j<threads_num;j++)
				if(dur[j]>duration)
					duration=dur[j];
			
			System.out.println("Execution Time: "+(duration/(1000000))+"ms");
			
			results[results_index++]=duration;
		}
		
		
		long mean=0;
		int count=0;
		for(int i=iters/2;i<=iters;i++){
			mean+=results[i];
			count++;
		}
		mean=mean/count;
		
		long stdev=0;
		for(int i=iters/2;i<=iters;i++){
			long t=mean-results[i];
			stdev+=t*t;
		}
		stdev=stdev/count;
		double stdev2=Math.sqrt((double)stdev);
		
		
		System.out.println("\n\n============================================");
		System.out.println("Average: "+mean/1000000.0+"ms");
		System.out.println("Standard Deviation: "+stdev2/1000000+"ms");
		
		
	}
}