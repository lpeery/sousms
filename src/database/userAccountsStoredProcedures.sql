/*
	UA stored procedures
*/
/*
This Procedure must:
1. Check to see if the email entered by the user exists in the database
2. Return true of false
*/
drop procedure if exists doesEmailExist;
delimiter //
create procedure doesEmailExist(
	IN email varchar(40)
//
delimiter ;


/*
This Prodecure must:
1. Insert temporary password in the database
2. Return true (inserted) or false (failed)
*/
drop procedure if exists insertTempPassword;
delimiter//
create procedure insertTempPassword;
	IN email varchar(40)
	IN password varchar(40)

begin
insert into User values User(password);
select * from User;
end;
//
delimiter;

/*
this procedure must:
1. Query the db to see if username/email exists
2. If yes then compare password with password in db
3. Return true or false
*/
drop procedure if exists checkEmailPassword;
delimter//
create procedure checkEmailPassword(
	IN email varchar(40)
	IN password varchar(40)
	OUT success boolean
	)
begin
	IF 


/*
This procedure must:
1. query database 
2. return numShares, price, symbol, transDate (transaction date) for the specified userID
*/
getTradeHistory(IN UserID int(11))