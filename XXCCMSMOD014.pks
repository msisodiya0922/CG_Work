
CREATE OR REPLACE PACKAGE xxccms_employeesync_pkg AUTHID CURRENT_USER 
AS

 
---------------------------------------------------------------------------------------------
--
-- Procedure  : main
-- Description: The Purpose of Developing this main procedure is to interface employee
--              from SMS to CCMS System.
--
-- Parameters:
--  x_errbuf           OUT   VARCHAR2
--  x_retcode          OUT   NUMBER

-- Return:
---------------------------------------------------------------------------------------------

   PROCEDURE main( x_errbuf  OUT VARCHAR2
                  ,x_retcode OUT NUMBER
                 );
END xxccms_employeesync_pkg;
/

SHOW ERRORS;