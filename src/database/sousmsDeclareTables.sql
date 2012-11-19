/* 
    Declares tables needed by sousms
    Pete Nordquist 121019
    Pete Nordquist 121026 - finalized feed table and added
    conditional procedure, which is probably not the best way to do it.
*/

-- Name: Create Table(s) -- TransactionWithSubtypes
-- Description: Split the Transaction table into two 
--				inclusive subtypes: Stock (for trading of stock) 
--				and Cash (for deposits and trading of stock)
-- Author: DatabaseGroup
-- Date: 10/23/2012
/*
121109 - Nice work database team.  I reviewed the tables and made a couple
of changes, as you can see below.
*/


/*Create and use sousms*/
-- create database if not exists sousms;
-- use sousms;
/*
Since we are building the database by hand, we will let the build
team choose the name and create the database as shown at the top
of sousmsInit.sql
*/

/* Holds the list of symbols in our Market */
-- Needed, so the users know which symbols they can buy and sell
-- and so the feed knows what to pull
CREATE TABLE IF NOT EXISTS Symbol(
	SymID int,
	Symbol varchar(8), -- same as the feed gives to us.
	primary key (SymID)
)Engine=InnoDB;

/*Stores User Data*/
CREATE TABLE IF NOT EXISTS User(
	UserID int auto_increment,
	Password varchar (40) not null,
	Fname char (20) not null,
	Lname char (20) not null,
	Email varchar (40) not null,
	Phone varchar (20) not null,
	PRIMARY KEY (UserID)
)ENGINE = InnoDB;
	
/*Login Data*/
CREATE TABLE IF NOT EXISTS Login(
	UserID int not null,
	Token varchar (32) not null,
	begTS timestamp not null,
	endts timestamp not null,
	PRIMARY KEY (Token, begTS),
	Foreign key (UserID) References User(UserID)
)ENGINE = InnoDB;

/*Stores user transaction data (Pertaining to stocks)*/
CREATE TABLE IF NOT EXISTS Stock(
	UserID int,
	SymID int,
	TStamp timestamp not null,
	SellBuy binary (1) not null,
	Shares int not null,
	Price float (10,4) not null,
	Primary Key (UserID, SymID, TStamp), 
	Foreign Key (UserID) References User(UserId)
		on update cascade,
	Foreign Key (SymID) References Symbol(SymID)
		on update cascade
)ENGINE = InnoDB;

/*Stores user's cash transactions */
CREATE TABLE IF NOT EXISTS Cash(
	UserID int not null,
	Balance float(9,2) not null,
	TStamp timestamp not null,
	Primary Key (UserID, Balance, TStamp),
	Foreign Key (UserID) References User(UserID)
		on update cascade
)ENGINE = InnoDB;

/*Stores users current stock holdings*/
CREATE TABLE IF NOT EXISTS Portfolio(
	UserID int not null,
	SymID int not null,
	DateModified timestamp not null,
	Shares int not null,
	Primary Key(UserID, SymID),
	Foreign Key (UserID) References User(UserID)
		on update cascade,
	Foreign Key (SymID) References Symbol(SymID)
		on update cascade
)Engine=InnoDB;

/* captures data from the feed */
create table if NOT exists Feed(
	symbol          varchar(8)      not null,
	bestAskPrice    decimal(10,4)   not null, 
		-- The format says: $$$$$$.dddd, which is 10,4 not 7,2
		-- copy the format and field names of the feed exactly
	bestAskQty      int             not null,
	bestBidPrice    decimal(10,4)   not null,
	bestBidQty      int             not null,
	close           decimal(10,4),     -- close can be null
	high            decimal(10,4)   not null,
	date            date            not null,
	time            time            not null,  
		-- (stores only down to the second,
		-- so store ms in the next field)
	ms              decimal(3,3)    not null,
		-- date, time, ms marks the time the feed request was executed,
		-- NOT the time of the last trade
	lastSale        decimal(10,4)   not null,
	low             decimal(10,4)   not null,
	netChg          decimal(10,4)   not null,
	open            decimal(10,4)   not null,
	pcl             decimal(10,4)   not null,
	vol             int             not null,
	pctChg          decimal(10,8)   not null,  
		-- pctChg was specified as numeric(11) by NASDAQ,
		-- which is the same precision
		-- as the others whose format was decimal(10,4), 
		-- so we can probably get away with decimal(10,8)
	CONSTRAINT FEED_PK PRIMARY KEY(date, symbol, vol),
		-- Keep the table in chronological order --
		-- these 3 fields are the ones that preserve the records
		-- we need and discard (as dups) the records we don't want,
		-- because every record from the feed has a
		-- different time stamp
	INDEX(symbol)
		-- need an index on symbol,
		-- so we can find group by symbol quickly
) ENGINE=INNODB;
