/*
	one-time Initialization script for SOUSMS database
	Pete Nordquist	121019

	Usage: 
	cd <directory-holding-sousmsInit.sql>
	mysql -v -u <desiredMYSQLuser> -p 
		create database <desiredDatabaseName>;
		use <desiredDatabaseName>;
		source sousmsInit.sql;
		exit;
*/


/* 
the source command is a handy command that
textually includes of the contents of the file you name

NOTE:
The file names following the source keyword are relative to 
the repository's src/database directory
where this script assumes it is running.
*/

-- initialize the tables
source sousmsDeclareTables.sql;
source sousmsTradeEngineTables.sql;

-- initialize the stored procedures
source ../shared/sousmsDeclareStoredProcs.sql;
source TradeEngineStoredProcedures.sql;

-- preload tables
source loadStockTable.sql;
source loadUserTable.sql;
source loadCashForUsers.sql;
