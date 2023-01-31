CREATE OR REPLACE PACKAGE AR_CUST_BAL_RPT_PKG
--
-- HEADER
--   Source control header
--
-- PROGRAM NAME
--  AR_CBSLRPTS.pls
--
-- DESCRIPTION
--  This script creates the package specification of AR_CUST_BAL_RPT_PKG
--  This package AUTHID CURRENT_USER is used to report on AR Customer Balance Statement Letter Report.
--
-- USAGE
--   To install       sqlplus <apps_user>/<apps_pwd> @AR_CBSLRPTS.pls
--   To execute       sqlplus <apps_user>/<apps_pwd> AR_CUST_BAL_RPT_PKG
--
-- PROGRAM LIST                DESCRIPTION
--
-- DEPENDENCIES
--   None
--
-- CALLED BY
--   Statement Generation Program.
--
-- LAST UPDATE DATE   24-Jun-2007
--   Date the program has been modified for the last time
--
-- HISTORY
-- =======
--
-- VERSION DATE           AUTHOR(S)        	   DESCRIPTION
-- ------- -----------    --------------           ------------------------------------
-- Draft1A 02-Feb-2007    Sajana Doma               Initial Creation
-- V_1.0   29-Sep-2011    Makaranddsingh Sisodiya   Updated Code For Modification  of MOD287
--
--************************************************************************
AS

-- To be used in query as bind variable

   P_RESP_APPLICATION_ID           NUMBER;
   P_CONC_REQUEST_ID	           NUMBER;
   P_SORT	                      VARCHAR2(500);
   P_SORT_BY_PHONETICS	          VARCHAR2(1);
   P_AS_OF_DATE	                  DATE;

   FUNCTION BeforeReport RETURN BOOLEAN;
   FUNCTION AfterReport RETURN BOOLEAN;

END AR_CUST_BAL_RPT_PKG;
/

