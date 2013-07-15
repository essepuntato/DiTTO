package it.essepuntato.ditto;

import it.essepuntato.ditto.MimeType;
import it.essepuntato.ditto.SourceExtractor;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringReader;
import java.net.URL;

import javax.servlet.ServletException;
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
		PrintWriter out;
		
		SourceExtractor extractor = new SourceExtractor(this);
		extractor.addMimeTypes(MimeType.mimeTypes);
		
		for (int i = 0; i < maxTentative; i++) {
			try {
				String stringURL = request.getParameter("diagram-url");
				
				URL diagramURL = new URL(stringURL);
				String content = extractor.exec(diagramURL);
				
				content = applyXSLTTransformation(
						content, 
						request.getParameter("ontology-url"),
						request.getParameter("ontology-prefix"),
						new Boolean(request.getParameter("look-across-for-labels")),
						getXSLT(request.getParameter("type")));
				
				response.setContentType("application/rdf+xml");
				response.setHeader("content-disposition", "attachment; filename=\"ontology.owl\"");
				out = response.getWriter();
				out.println(content);
				i = maxTentative;
			} catch (Exception e) {
				if (i + 1 == maxTentative) {
					response.setContentType("text/html");
					out = response.getWriter();
					out.println(getErrorPage(e));
				}
			}
		}
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
			}
		}	
		
		return result;
	}

	private String applyXSLTTransformation(
			String source, String ontologyURI, String ontologyPrefix, 
			boolean lookAcrossForLabels, String xsltURL) 
	throws TransformerException {	
		TransformerFactory tfactory = new net.sf.saxon.TransformerFactoryImpl();
		
		ByteArrayOutputStream output = new ByteArrayOutputStream();
		
		Transformer transformer =
			tfactory.newTransformer(
					new StreamSource(xsltURL));
		
		transformer.setParameter("ontology-prefix", ontologyPrefix);
		transformer.setParameter("ontology-uri", ontologyURI);
		transformer.setParameter("look-across-for-labels", lookAcrossForLabels);
		
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
	}
	
	private String getErrorPage(Exception e) {
		return "DiTTO error\nReason:\n\t" + e.getMessage();
	}
}
