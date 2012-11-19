/* 
 * Lists headers of, and/or information on, stored procedures needed by 
 * the Trade Engine team.
 */

-- sp_symbolToSymID
-- Converts a symbol to a symbol ID.
DROP PROCEDURE IF EXISTS sp_symbolToSymID;
DELIMITER //
CREATE PROCEDURE `sp_symbolToSymID` (
	stockSymbol varchar(8)
)
BEGIN
	SELECT symID FROM Symbol WHERE Symbol.symbol = stockSymbol;
END;
//

DELIMITER ;

-- sp_insertSell
DROP PROCEDURE IF EXISTS sp_insertSell;
DELIMITER //
CREATE PROCEDURE `sp_insertSell` (
	IN userID_in  int(11),
	IN symbolID_in  int(11),
	IN shares_in int(11),
	IN price_in  numeric(13,2)
)
BEGIN
	INSERT INTO OpenOrders (userID, symID, shares, orderType, price, requestTime) 
		VALUES (userID_in, symbolID_in, shares_in,
		(SELECT `typeID` FROM OrderTypes WHERE `description` LIKE 'Sell'), 
		price_in, NOW());
	SELECT 'Your trade has been queued.' AS statusmsg;
END;
//

DELIMITER ;

-- sp_getShareBalance
DROP PROCEDURE IF EXISTS sp_getShareBalance;
delimiter //
CREATE PROCEDURE sp_getShareBalance(
	IN userID_in  int(11),
	IN symbolID_in  int(11)
	)
BEGIN
	SELECT `Shares` FROM Portfolio  
	WHERE `UserID` = userID_in 
	AND `SymID` = symbolID_in;
END;
//

delimiter ;

-- sp_getAllOpenOrders
DROP PROCEDURE IF EXISTS sp_getAllOpenOrders;
DELIMITER //
CREATE PROCEDURE `sp_getAllOpenOrders` ()
BEGIN
	-- Returns all records of the OpenOrders table
	SELECT  openorders.orderID,
			openorders.userID, 
			openorders.symID, 
			symbol.symbol,
			openorders.shares,
			openorders.orderType,
			ordertypes.description AS typedesc,
			openorders.price
		FROM openorders
			JOIN symbol ON openorders.symID = symbol.symID
			JOIN ordertypes ON openorders.orderType = ordertypes.typeid
		ORDER BY orderID;
END;
//

DELIMITER ;

-- sp_deleteOpenOrder
-- deletes the record corresponding to orderID from OpenOrders
DROP PROCEDURE IF EXISTS sp_deleteOpenOrder;
DELIMITER //
CREATE PROCEDURE `sp_deleteOpenOrder` (orderID INT)
BEGIN
	DELETE FROM openorders WHERE openorders.orderID = orderID;
END;
//

DELIMITER ;

-- sp_getUserIdFromToken
DROP PROCEDURE IF EXISTS sp_getUserIdFromToken;
DELIMITER //
CREATE PROCEDURE `sp_getUserIdFromToken`(
	token char(32)
)
BEGIN
	DECLARE lnUserID INT;
	DECLARE ldExpireTime TIMESTAMP;
	DECLARE loginCursor CURSOR FOR SELECT UserID, EndTS FROM login
		WHERE logins.token = token;
	DECLARE EXIT HANDLER FOR NOT FOUND BEGIN
		SELECT -1 AS userid, 'The login was not found' AS statusmsg;
	END;
	OPEN loginCursor;
	FETCH loginCursor INTO lnUserID, ldExpireTime;
	CLOSE loginCursor;
	IF ldExpireTime > NOW() THEN
		SELECT lnUserID AS userid, '' AS statusmsg; 
	ELSE
		SELECT -1 AS userid, 'The login expired' AS statusmsg; 
	END IF;
END;
//

DELIMITER ;

-- sp_insertBuy
-- Nov 5, 2012 Created By Jeff Karmy, with Jeff Miller's help
DROP PROCEDURE IF EXISTS sp_insertBuy;
DELIMITER //
CREATE PROCEDURE `sp_insertBuy` (
	IN userID int,
	IN symbolID int,
	IN shares int,
	IN price numeric(13,2)
)
BEGIN
	INSERT INTO OpenOrders (userID, symID, shares, orderType, price, requestTime)
	VALUES (userID, symbolID, shares, (SELECT typeID FROM OrderTypes WHERE description LIKE 'Buy'), price, NOW());
	SELECT 'Your trade has been queued' AS statusmsg;
END;
//

DELIMITER ;

-- sp_getCash
-- returns user's cash
DROP PROCEDURE IF EXISTS sp_getCash;
DELIMITER //
CREATE PROCEDURE `sp_getCash` (
	userID INT
)
BEGIN
	SELECT SUM(balance) AS totalbalance FROM cash WHERE cash.userID = userID;
END;
//

DELIMITER ;

-- sp_getPrice
-- returns latest stock price
DROP PROCEDURE IF EXISTS sp_getPrice;
DELIMITER //
CREATE PROCEDURE `sp_getPrice` (
	symID INT
)
BEGIN
	SELECT bestAskPrice AS price
	FROM feed
		JOIN symbol ON symbol.symbol = feed.symbol
	WHERE symbol.symID = symID
	ORDER BY feed.date DESC,
		feed.time DESC
	LIMIT 1;
END;
//

DELIMITER ;

-- sp_buy
-- executes "buy" behavior for given order ID:
--   get current cash, current price, limit price
--   let total price = current price * number of shares
--   if limit price is not null and limit price is greater than total price
--     status is "limit price has not been met", skip to end
--   if current cash is greater than or equal to total price
--     insert negative balance (-1 * total price) into "cash" table for given user
--     insert into stock holdings (userID, symID) if not exists
--     update stock holdings (shares, datemodified) in "portfolio" table for (userID, symID)
--     delete order for given order ID
--     roll back changes if any failures
--   report status
DROP PROCEDURE IF EXISTS sp_buy;
DELIMITER //
CREATE PROCEDURE `sp_buy` (
	openOrderID INT
)
BEGIN
	DECLARE lnUserID, lnSymID, lnShares INT;
	DECLARE lnLimitPrice, lnCurrentCash, lnCurrentPrice, lnTotalPrice NUMERIC(13,2);
	BEGIN
		DECLARE openordersCursor CURSOR FOR
			SELECT userID, symID, shares, price
			FROM openorders JOIN ordertypes ON openorders.orderType = ordertypes.typeID
			WHERE openorders.orderid = openOrderID AND ordertypes.description = 'Buy';
		DECLARE EXIT HANDLER FOR NOT FOUND BEGIN
			SELECT CONCAT('Buy order #', openOrderID, ' not found.') AS statusmsg;
		END;
		OPEN openordersCursor;
		FETCH openordersCursor INTO lnUserID, lnSymID, lnShares, lnLimitPrice;
		CLOSE openordersCursor;
	END;
	BEGIN
		DECLARE cashCursor CURSOR FOR
			SELECT SUM(balance) FROM cash WHERE cash.userID = userID;
		DECLARE EXIT HANDLER FOR NOT FOUND BEGIN
			SELECT 'User has no account.' AS statusmsg;
		END;
		OPEN cashCursor;
		FETCH cashCursor INTO lnCurrentCash;
		CLOSE cashCursor;
	END;
	BEGIN
		DECLARE priceCursor CURSOR FOR
			SELECT bestAskPrice AS price
			FROM feed
				JOIN symbol ON symbol.symbol = feed.symbol
			WHERE symbol.symID = symID
			ORDER BY feed.date DESC,
				feed.time DESC
			LIMIT 1;
		DECLARE EXIT HANDLER FOR NOT FOUND BEGIN
			SELECT 'Stock price not found in feed.' AS statusmsg;
		END;
		OPEN priceCursor;
		FETCH priceCursor INTO lnCurrentPrice;
		CLOSE priceCursor;
	END;
	IF NOT ISNULL(lnUserID) AND NOT ISNULL(lnSymID) AND NOT ISNULL(lnShares) AND NOT ISNULL(lnCurrentCash) AND NOT ISNULL(lnCurrentPrice) THEN
		SET lnTotalPrice = lnCurrentPrice * lnShares;
		IF NOT ISNULL(lnLimitPrice) AND lnLimitPrice > lnTotalPrice THEN
			SELECT 'Limit price not yet reached.' AS statusmsg;
		ELSE
			IF lnCurrentCash < lnTotalPrice THEN
				SELECT 'Not enough cash on hand to complete transaction.' AS statusmsg;
			ELSE
				INSERT INTO cash (UserID, Balance) VALUES (lnUserID, (-1 * lnTotalPrice));
				INSERT IGNORE INTO portfolio (UserID, SymID, Shares) VALUES (lnUserID, lnSymID, 0);
				UPDATE portfolio SET
					Shares = Shares + lnShares,
					DateModified = NOW()
				WHERE UserID = lnUserID AND SymID = lnSymID;
				DELETE FROM openorders WHERE openorders.orderID = openOrderID;
				SELECT CONCAT('Buy order #', openOrderID, ' completed successfully.') AS statusmsg;
			END IF;
		END IF;
	END IF;
END;
//

DELIMITER ;

-- sp_sell
DROP PROCEDURE IF EXISTS sp_sell;
DELIMITER //
CREATE PROCEDURE `sp_sell` (
	openOrderID INT
)
BEGIN
	
END;
//

DELIMITER ;

