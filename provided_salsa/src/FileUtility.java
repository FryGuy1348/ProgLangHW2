package src;
import java.io.*;
import java.util.*;


/*

  A file read/write utility.

  Not used for grading.
  You may adjust function signatures and create 
  helper functions as necessary.

*/

class FileUtility {

		private Queue<String> script;


    /* read in the input script file */
    FileUtility(String scriptFile){
    	Scanner scriptScanner = new Scanner(load(scriptFile));
    	script = new LinkedList<String>();

      while (scriptScanner.hasNextLine()) {
      	String s = scriptScanner.nextLine();
      	// System.out.println(s);
      	script.add(s);
      }

  		scriptScanner.close();
    }


    /* retrieve the next line of the input script file 
     * returns null if there are no additional lines
     */
    String nextLine() { return nextLine(0); }

    String nextLine(int sleepInterval){
    	try {
    		Thread.sleep(sleepInterval);
    	} catch (InterruptedException e) {}

	    return script.poll();
    }

		
		/* Ensure the given directory exists.
		 * 
		 * If it does exist, contents are kept.
		 */
		static void mkdir(String dir) {		
	    new File(dir).mkdirs(); 
		}


    /* Save some data to file.
     *
     * Relative addresses are accepted ("out/f.txt").
     * If the file is not present, print an error to standard error.
     */
    static void save(String filePath, String contents) {
	    File fileOut = new File(filePath);
	    FileWriter writer;

	    // standardOutput<-println("Save: " + dir + " " + fileAddress + " " + contents);

	    try{
	      if (!fileOut.exists()){
	        fileOut.createNewFile();
	      }

	      writer = new FileWriter(filePath, false); // filepath, append
	      writer.write(contents);
	      writer.close();
	    } catch (IOException ioe){
	      System.err.println(ioe.getMessage());
	    }
    }


    /* Load some data 
     *
     * Relative addresses are accepted ("out/f.txt").
     * If a file is not present, return an empty string.
     */
    static String load(String filePath) {
		    StringBuilder content = new StringBuilder();
	    	String line;

		    try {
		      BufferedReader in = new BufferedReader(new FileReader(filePath));

		      while ((line = in.readLine()) != null){
		        content.append(line);
		        content.append("\n");
		      }
		      
		      in.close(); 
		    } catch (IOException ioe){
		      System.err.println("[error] Can't open the file "+filePath+" for reading.");
		      System.err.println(ioe.getMessage());
		      return "";
		    }

      	// standardOutput<-println("Load: " + inFileName + " " + content.toString());

				// the above loop adds an extra "\n" to loaded files.  It is removed here.
		    return content.toString().substring(0,content.length()-1);
    }

}