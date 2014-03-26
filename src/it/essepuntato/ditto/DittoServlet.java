package it.essepuntato.ditto;

import it.essepuntato.ditto.MimeType;
import it.essepuntato.ditto.SourceExtractor;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.eclipse.jdt.internal.compiler.impl.BooleanConstant;

/**
 * Servlet implementation class DittoServlet
 */
public class DittoServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private String erMinimal;
	private String erIntermediate;
	private String erMaximal;
	private String graffoo;
	private int maxTentative = 3;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public DittoServlet() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		resolvePaths(request); /* Set all paths */
		response.setCharacterEncoding("UTF-8");
		ServletOutputStream out = null;
		
		SourceExtractor extractor = new SourceExtractor(this);
		extractor.addMimeTypes(MimeType.mimeTypes);
		
		for (int i = 0; i < maxTentative; i++) {
			try {
				String stringURL = request.getParameter("diagram-url");
				
				URL diagramURL = new URL(stringURL);
				String content = extractor.exec(diagramURL);
				String type = request.getParameter("type");
				
				content = applyXSLTTransformation(
						content, 
						request.getParameter("ontology-url"),
						request.getParameter("ontology-prefix"),
						new Boolean(request.getParameter("look-across-for-labels")),
						new Boolean(request.getParameter("main-ontology-only")),
						new Boolean(request.getParameter("version-iri-imported")),
						getXSLT(type), type).trim();
				
				if (type.equals("graffoo")) {
					String[] tempOntologies = content.split("\r\r\r");
					List<String> finalOntologies = new ArrayList<String>(); 
					for (String tempOntology : tempOntologies) {
						if (!tempOntology.replaceAll("\\s+", "").trim().equals("")) {
							finalOntologies.add(tempOntology);
						}
					}
					
					if (finalOntologies.size() > 1) {
						response.setContentType("application/zip"); /* ZIP file in case of multiple ontologies */
						response.setHeader("content-disposition", "attachment; filename=\"ontologies.zip\"");
						out = response.getOutputStream();
						createZipFile(finalOntologies, out);
						
					} else {
						response.setContentType("text/plain"); /* Manchester Syntax */
						response.setHeader("content-disposition", "attachment; filename=\"ontology.owl\"");
						out = response.getOutputStream();
						out.write(content.getBytes());
					}
					
				} else {
					response.setContentType("application/rdf+xml");  /* RDF/XML */
					response.setHeader("content-disposition", "attachment; filename=\"ontology.owl\"");
					out = response.getOutputStream();
					out.write(content.getBytes());
				}
				
				out.flush();
				i = maxTentative;
			} catch (Exception e) {
				if (i + 1 == maxTentative) {
					response.setContentType("text/html");
					//out = response.getWriter();
					out.println(getErrorPage(e));
				}
			}
		}
	}
	
	private ByteArrayOutputStream createZipFile(List<String> list, OutputStream out) throws IOException {
		ByteArrayOutputStream b = new ByteArrayOutputStream(); 
		ZipOutputStream zip = new ZipOutputStream(out);
		for (int i = 0; i < list.size(); i++) {
			String ontology = list.get(i);
			InputStream is = new ByteArrayInputStream(ontology.getBytes());
			ZipEntry entry = new ZipEntry("ontology_" + (i+1) + ".owl");
			zip.putNextEntry(entry);
			int len;
			byte[] buf = new byte[1024]; 
			while ((len = is.read(buf)) > 0) {
				zip.write(buf, 0, len);
			}
			zip.closeEntry();
			is.close();
		}
		zip.close();
		return b;
	}

	private String getXSLT(String parameter) {
		String result = erMaximal;
		
		if (parameter != null) {
			if (parameter.equals("er-minimal")) {
				result = erMinimal;
			} else if (parameter.equals("er-intermediate")) {
				result = erIntermediate;
			} else if (parameter.equals("er-maximal")) {
				result = erMaximal;
			} else if (parameter.equals("graffoo")) {
				result = graffoo;
			}
		}	
		
		return result;
	}

	private String applyXSLTTransformation(
			String source, String ontologyURI, String ontologyPrefix, 
			boolean lookAcrossForLabels, boolean mainOntologyOnly, boolean versionIRIImported, 
			String xsltURL, String type) 
	throws TransformerException {	
		TransformerFactory tfactory = new net.sf.saxon.TransformerFactoryImpl();
		
		ByteArrayOutputStream output = new ByteArrayOutputStream();
		
		Transformer transformer =
			tfactory.newTransformer(
					new StreamSource(xsltURL));
		
		if (type.equals("graffoo")) {
			if (ontologyURI != null && !ontologyURI.equals("")) {
				transformer.setParameter("default-empty-prefix-param", ontologyURI + "/");
				transformer.setParameter("default-ontology-iri-param", ontologyURI);
			}
			transformer.setParameter("use-imported-ontology-version-iri-param", versionIRIImported);
			transformer.setParameter("generate-all-ontologies-param", !mainOntologyOnly);
		} else {
			transformer.setParameter("ontology-prefix", ontologyPrefix);
			transformer.setParameter("ontology-uri", ontologyURI);
			transformer.setParameter("look-across-for-labels", lookAcrossForLabels);
		}
		
		StreamSource inputSource = new StreamSource(new StringReader(source));
		
		transformer.transform(
				inputSource, 
				new StreamResult(output));
		
		return output.toString();
	}
	
	private void resolvePaths(HttpServletRequest request) {
		erMinimal = getServletContext().getRealPath("er-minimal.xsl");
		erIntermediate = getServletContext().getRealPath("er-intermediate.xsl");
		erMaximal = getServletContext().getRealPath("er-maximal.xsl");
		graffoo =  getServletContext().getRealPath("graffoo.xsl");
	}
	
	private String getErrorPage(Exception e) {
		return "DiTTO error\nReason:\n\t" + e.getMessage();
	}
}
