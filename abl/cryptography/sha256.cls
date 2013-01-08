 
 /*------------------------------------------------------------------------
    File        : sha256
    Purpose     : 
    Syntax      : 
    Description : Converts text to a SH256 encoded value.
    Author(s)   : paul.mowat
    Created     : Tue Nov 27 09:41:57 GMT 2012
    Notes       : Not introduced into core Progress until V11
        
    text: mynameispaul
    
    hex   : cd88a8935f9ca75092a58b16defc47b490b09067c1dde63ff346ee0f8b31c729
    base64: zYiok1+cp1CSpYsW3vxHtJCwkGfB3eY/80buD4sxxyk=      
        
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING System.Security.Cryptography.*.
USING System.Text.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS abl.cryptography.sha256: 
  
	/*------------------------------------------------------------------------------
    Purpose:  Conversts a string into a SHA256 code																  
		Notes:  																	  
	------------------------------------------------------------------------------*/		
				
  /*------------------------------------------------------------------------------
    Purpose: Calculates Hash and stores as a byte array 																  
		Notes:  																	  
	------------------------------------------------------------------------------*/	
				
	CONSTRUCTOR PUBLIC sha256 ( ):
		SUPER ().		
           		
	END CONSTRUCTOR.

  
  /*------------------------------------------------------------------------------
    Purpose: Converts byte array into Hex string                                                                
    Notes:                                                                        
  ------------------------------------------------------------------------------*/
  
  METHOD PUBLIC CHARACTER ConvertToHex( INPUT ip_cTextToHash AS CHARACTER ):
      
      DEFINE VARIABLE lv_bText          AS "System.Byte[]" NO-UNDO.
      DEFINE VARIABLE lv_bHashedBytes   AS "System.Byte[]" NO-UNDO. 
      DEFINE VARIABLE lv_oSHA256Managed AS SHA256Managed NO-UNDO.
      
      ASSIGN lv_oSHA256Managed = NEW SHA256Managed()
             lv_bText          = System.Text.Encoding:UTF8:GetBytes(ip_cTextToHash)
             lv_bHashedBytes   = lv_oSHA256Managed:ComputeHash(lv_bText).
      
      DEFINE VARIABLE lv_oStringBuilder AS StringBuilder NO-UNDO.
      DEFINE VARIABLE lv_oHashedBytesEnumerator AS System.Collections.IEnumerator NO-UNDO.
                      
      ASSIGN lv_oStringBuilder         = NEW StringBuilder()
             lv_oHashedBytesEnumerator = lv_bHashedBytes:GetEnumerator().                             
  
      lv_oHashedBytesEnumerator:Reset().
      
      DO WHILE lv_oHashedBytesEnumerator:MoveNext() ON ERROR UNDO, THROW:
          lv_oStringBuilder:AppendFormat("~{0:x2~}", CAST(lv_oHashedBytesEnumerator:Current, "System.Byte")).
      END.
  
      RETURN lv_oStringBuilder:ToString().
  
  END METHOD.

        
  /*------------------------------------------------------------------------------
    Purpose: Converts byte array into base64 string                                                                      
    Notes:                                                                        
  ------------------------------------------------------------------------------*/
  
  METHOD PUBLIC CHARACTER ConvertToBase64( INPUT ip_cTextToHash AS CHARACTER ):      
      
      DEFINE VARIABLE lv_bText          AS "System.Byte[]" NO-UNDO.
      DEFINE VARIABLE lv_bHashedBytes   AS "System.Byte[]" NO-UNDO. 
      DEFINE VARIABLE lv_oSHA256Managed AS SHA256Managed NO-UNDO.
      
      ASSIGN lv_oSHA256Managed = NEW SHA256Managed()
             lv_bText          = System.Text.Encoding:UTF8:GetBytes(ip_cTextToHash)
             lv_bHashedBytes   = lv_oSHA256Managed:ComputeHash(lv_bText).
      
      RETURN System.Convert:ToBase64String(lv_bHashedBytes).
    
  END METHOD.
    
END CLASS.
