 
 /*------------------------------------------------------------------------
    File        : irmark
    Purpose     : Generates the Inland Revenue Mark required by xml files
                  that are sent to them.
    Syntax      : 
    Description : Generates the Inland Revenue Mark
    Author(s)   : paul.mowat
    Created     : Tue Nov 27 09:47:52 GMT 2012
    Notes       : Does whats required but uses alot of memory and can crash
                  on files greater than approx 50mb with an out of memory 
                  exception.
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

USING System.*.
USING System.Collections.Generic.*.
USING System.Text.*.
USING System.Xml.*.
USING System.Security.Cryptography.*.
USING System.Security.Cryptography.Xml.*.
USING System.IO.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS ABL.Misc.IRMark: 

  /*------------------------------------------------------------------------------
	  Purpose:  																	  
    Notes:  																	  
	------------------------------------------------------------------------------*/
		
	CONSTRUCTOR PUBLIC IRMark ( ):
		SUPER ().
				
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
    Purpose: Generates the IRMark for the required file   																	  
		Notes:  																	  
	------------------------------------------------------------------------------*/

	METHOD PUBLIC CHARACTER GenerateIRMarkFromFile(INPUT ip_cXMLFile AS CHARACTER, 
                                                 INPUT ip_cTaxNamespace AS CHARACTER,
                                                 INPUT ip_cEnvelopeNameSpace AS CHARACTER ):
		
		
		DEFINE VARIABLE xmlDoc   AS  "XmlDocument" NO-UNDO.
		DEFINE VARIABLE xmlBody  AS  "XmlDocument" NO-UNDO.
		DEFINE VARIABLE nodeBody AS  "XmlNode"     NO-UNDO.
		DEFINE VARIABLE nodeIr   AS  "XmlNode"     NO-UNDO.
		
		DEFINE VARIABLE c14n  AS "XmlDsigC14NTransform" NO-UNDO.
		DEFINE VARIABLE s     AS "System.IO.MemoryStream" NO-UNDO.
		DEFINE VARIABLE sha   AS "SHA1CryptoServiceProvider" NO-UNDO.
		DEFINE VARIABLE hash  AS "System.Byte[]" NO-UNDO.
		DEFINE VARIABLE sHash AS CHARACTER NO-UNDO.
						
    /*
    ** Load XML
    */	
		ASSIGN xmlDoc  = NEW System.Xml.XmlDocument().
		xmlDoc:PreserveWhitespace = TRUE.
		xmlDoc:Load(INPUT ip_cXMLFile).

		/*
		** Create Namespace for parameters
		*/
		DEFINE VARIABLE ns AS CLASS XmlNamespaceManager NO-UNDO.
		ASSIGN ns = NEW XmlNamespaceManager(INPUT xmlDoc:NameTable).
		ns:AddNamespace("tax", ip_cTaxNamespace).
		ns:AddNamespace("env", ip_cEnvelopeNameSpace).
				
	  /*
	  ** Get body portion of XML Document
	  */
		ASSIGN nodeBody = xmlDoc:SelectSingleNode(INPUT "//env:Body", 
		                                          INPUT ns).   
    xmlDoc = ?. /* try free up memory */

    /*
    ** Create XML document of just the body section
    */
		ASSIGN xmlBody  = NEW System.Xml.XmlDocument().
    xmlBody:PreserveWhitespace = TRUE.
    xmlBody:LoadXML(INPUT nodeBody:OuterXml).
		
		nodeBody = ?. /* try free up memory */
		
		/*
		** Remove any existing IRMark
		*/
		ASSIGN nodeIr = xmlBody:SelectSingleNode(INPUT "//tax:IRmark",
		                                         INPUT ns).
		                                         
    IF nodeIr <> ? THEN
      nodeIr:ParentNode:RemoveChild(nodeIr). 

    ns  = ?. /* try free up memory */

    /*
    ** Normalise the document using C14N (Canonicalisation)
    */
    c14n = NEW System.Security.Cryptography.Xml.XmlDsigC14NTransform().
    c14n:LoadInput(INPUT xmlBody).
    s = CAST(c14n:GetOutput(Progress.Util.TypeHelper:GetType("System.IO.Stream")), "System.IO.MemoryStream").

    xmlBody = ?.
    c14n    = ?. /* try free up memory */
        
    /*
    ** Read Normalised document back into string
    */
    DEFINE VARIABLE b AS "System.Byte[]" NO-UNDO.
    b = s:ToArray().

    s = ?. /* try free up memory */                                  
           
    /*
    ** Modify the string to conform to the normalised spec
    */         
    DEFINE VARIABLE enc AS "System.Text.UTF8Encoding" NO-UNDO.
    enc = NEW System.Text.UTF8Encoding().
    
    DEFINE VARIABLE sNormalised     AS LONGCHAR NO-UNDO.      
    DEFINE VARIABLE sNormalisedMptr AS MEMPTR   NO-UNDO.
    
    ASSIGN sNormalised = enc:GetString(INPUT b).
    
    b = ?. /* try free up memory */
    
    /*
    ** There seems to be a funny with progress retrieving the longchar
    ** value from .NET. it's pulling it back with the wrong codetable. 
    ** The data is correct so we're just going to stick it into a memory 
    ** pointer and get it back
    */
    COPY-LOB sNormalised TO sNormalisedMptr NO-CONVERT.
    COPY-LOB sNormalisedMptr TO sNormalised.
    SET-SIZE(sNormalisedMptr) = 0.  
    sNormalisedMptr = ?.
    
    ASSIGN sNormalised = REPLACE(sNormalised,"&#xD;","")
           sNormalised = REPLACE(sNormalised,"\r\n","\n")
           sNormalised = REPLACE(sNormalised,"\r","\n")
           sNormalised = SUBSTRING(sNormalised,1, LENGTH(sNormalised)).   
    
    /*
    ** Convert the final document back into a byte array
    */    
    b = enc:GetBytes(INPUT sNormalised).
    
    sNormalised = ?. /* try free up memory */

    /*
    ** Create the SHA-1 hash from the final document
    */
    ASSIGN sha   = NEW SHA1CryptoServiceProvider()
           hash  = sha:ComputeHash(INPUT b).
           
    b = ?. /* try free up memory */           
           
    ASSIGN sHash = System.Convert:ToBase64String(INPUT hash).
    
    RETURN sHash.          
		
	END METHOD.
    
END CLASS.