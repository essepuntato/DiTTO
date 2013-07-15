package it.essepuntato.ditto;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.List;

public class SourceExtractor {
	private List<String> mimeTypes;
	private DittoServlet s;
	public SourceExtractor() {
		mimeTypes = new ArrayList<String>();
	}
	
	public SourceExtractor(DittoServlet s) {
		this.s = s;
		mimeTypes = new ArrayList<String>();
	}
	
	public void addMimeType(String mimeType){
		mimeTypes.add(mimeType);
	}
	
	public void addMimeTypes(String[] mimeTypes) {
		for (String mimeType : mimeTypes) {
			addMimeType(mimeType);
		}
	}
	
	public void removeMimeType(String mimeType){
		mimeTypes.remove(mimeType);
	}
	
	public String exec(URL url) throws IOException {
		String result = "";
		
		for (String mimeType : mimeTypes) {
			try {
				URLConnection connection = url.openConnection();
				connection.setRequestProperty("User-Agent", "DiTTO extractor");
				connection.setRequestProperty("Accept", mimeType);
				
				BufferedReader in = new BufferedReader(
						new InputStreamReader(connection.getInputStream()));
			
				String line;
				while ((line = in.readLine()) != null) {
					result += line + "\n";
				}
				
				in.close();
				break;
			} catch (Exception e) {
				// Do nothing
			}
		}
		
		if (result == null || result.equals("")) {
			throw new IOException("The source can't be downloaded in any permitted format.");
		} else {
			return result;
		}
	}
}
