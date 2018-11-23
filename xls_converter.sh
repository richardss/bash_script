#!/bin/bash
export ORACLE_HOME="/opt/oracle/product/11.2.0.3_cl"
FILE="/prod/dati/prova.xls"
/swlocal/oracle/bin/sqlplus -S user/password@example.com:1521/example <<ENDOFSQL

SET PAGESIZE 50000
SET FEEDBACK OFF 
SET MARKUP HTML ON SPOOL ON
SET NUM 24
SPOOL $FILE

SELECT A.AZIENDA,     
       A.VOCE,                                     
       A.RAP_FORMA_TEC,           
       A.NDG,                                       
       SUBSTR(A.CONTO,1,18) AS CONTO,               
       A.PROGR_RAPPORTO, 
       A.KEY_TP_ELABORAZ,      
       A.TCH_MODELLO,              
       A.Q09980 AS PARTECIPA_RISCHIO_GEN_SPEC,                           
       A.Q09984 AS METODO,           
       A.TCH_MET_CALC_RMK AS QF2046, 
       A.IMPORTO_CTV,                               
       A.P00007 AS VALUTA,             
       A.P00032 AS COD_ISIN                        
FROM   TUKB510.TNXNVIG A                                       
WHERE  A.AZIENDA IN ('UUD01','UUD02')                             
  AND  A.KEY_TP_ELABORAZ = 'STAR'                              
  AND  A.TCH_MODELLO='STAR'                                    
  AND  A.Q09984 = 0                                          
     AND  A.DATA_RIFERIMENTO = '20180630'        
   AND  SUBSTR(A.VOCE,1,5) <> '05800'                
 GROUP BY A.AZIENDA, A.VOCE , A.RAP_FORMA_TEC,   
          A.NDG, A.CONTO, A.PROGR_RAPPORTO,          
          A.KEY_TP_ELABORAZ, A.TCH_MODELLO, A.Q09980,
          A.Q09984,A.TCH_MET_CALC_RMK, A.IMPORTO_CTV,
          A.P00007, A.P00032                         
 ORDER BY RAP_FORMA_TEC,NDG,CONTO                    ;

SPOOL OFF
SET MARKUP HTML OFF SPOOL OFF
exit;
ENDOFSQL


