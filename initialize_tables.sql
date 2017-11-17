DELIMITER $$
CREATE DEFINER=`F17336Pskatehi`@`%` PROCEDURE `initialize_tables`(IN `numberofinstruments` INT)
BEGIN

	/* Declarations */
	DECLARE counter int;
    DECLARE instrument_index int;
    
    /* Default Values */
	SET counter=0;

	DROP TABLES IF EXISTS INSTRUMENT, QUOTE_ADJUST, STOCK_QUOTE_FEED, STOCK_HISTORY, STOCK_TRADE;
    
    CREATE TABLE `INSTRUMENT` (
  `INSTRUMENT_ID` int(11) NOT NULL UNIQUE PRIMARY KEY,
  `INSTR_TYPE_ID` int(11) DEFAULT NULL,
  `CURRENCY_ID` int(11) DEFAULT NULL,
  `MAJOR_IDST_CLS_ID` int(11) DEFAULT NULL,
  `SCND_IDST_CLS_ID` int(11) DEFAULT NULL,
  `GEO_GROUP_ID` int(11) DEFAULT NULL,
  `COUNTRY_ID` int(11) DEFAULT NULL,
  `CAPITALIZATION_ID` int(11) DEFAULT NULL,
  `TRADING_SYMBOL` varchar(15) DEFAULT NULL,
  `CUSIP_NUMBER` varchar(80) DEFAULT NULL,
  `INSTR_NAME` varchar(30) DEFAULT NULL,
  `INSTR_DESC` varchar(255) DEFAULT NULL,
  `ISSUED_DATE` date DEFAULT NULL
);

    CREATE TABLE `QUOTE_ADJUST` (
  `INSTRUMENT_ID` int(11) NOT NULL PRIMARY KEY,
  `LAST_ASK_PRICE` decimal(18,4) DEFAULT '0.0000',
  `LAST_ASK_SEQ_NBR` int(11) DEFAULT '0',
  `LAST_BID_PRICE` decimal(18,4) DEFAULT '0.0000',
  `LAST_BID_SEQ_NBR` int(11) DEFAULT '0',
  `AMPLITUDE` decimal(18,4) DEFAULT '0.0000',
  `SWITCHPOINT` int(11) DEFAULT '0',
  `DIRECTION` tinyint(4) DEFAULT '1'
);

CREATE TABLE `STOCK_QUOTE_FEED` (
  `INSTRUMENT_ID` int(11) NOT NULL,
  `QUOTE_DATE` date NOT NULL,
  `QUOTE_SEQ_NBR` int(11) NOT NULL,
  `TRADING_SYMBOL` varchar(15) DEFAULT NULL,
  `QUOTE_TIME` datetime DEFAULT NULL,
  `ASK_PRICE` decimal(18,4) DEFAULT NULL,
  `ASK_SIZE` int(11) DEFAULT NULL,
  `BID_PRICE` decimal(18,4) DEFAULT NULL,
  `BID_SIZE` int(11) DEFAULT NULL,
   PRIMARY KEY (`INSTRUMENT_ID`, `QUOTE_DATE`, `QUOTE_SEQ_NBR`)
);

CREATE TABLE `STOCK_TRADE` (
    `INSTRUMENT_ID` int(11) NOT NULL,
    `TRADE_DATE` date NOT NULL,
    `TRADE_SEQ_NBR` int(11) NOT NULL,
    `TRADING_SYMBOL` varchar(15) DEFAULT NULL,
    `TRADE_TIME` datetime DEFAULT NULL,
    `TRADE_PRICE` decimal(18,4) DEFAULT NULL,
    `TRADE_SIZE` int(11) DEFAULT NULL,
    PRIMARY KEY (`INSTRUMENT_ID`, `TRADE_DATE`, `TRADE_SEQ_NBR`)
);

CREATE TABLE `STOCK_HISTORY` (
    `INSTRUMENT_ID` INT(11) NOT NULL,
    `TRADE_DATE` DATE NOT NULL,
    `TRADING_SYMBOL` VARCHAR(15) DEFAULT NULL,
    `OPEN_PRICE` DECIMAL(18,4) DEFAULT NULL,
    `CLOSE_PRICE` DECIMAL(18, 4) DEFAULT NULL,
    `LOW_PRICE` DECIMAL(18, 4) DEFAULT NULL,
    `HIGH_PRICE` DECIMAL(18, 4) DEFAULT NULL,
    `VOLUME` INT(11) DEFAULT NULL,
    PRIMARY KEY (`INSTRUMENT_ID`, `TRADE_DATE`)
);
    
	WHILE counter < (numberofinstruments) DO
    	SET instrument_index=FLOOR(RAND()*2000);
    	INSERT INTO INSTRUMENT SELECT * from stockmarket.INSTRUMENT WHERE instrument_id = instrument_index;
        SET counter=counter+1;
        END WHILE;
        
    INSERT INTO QUOTE_ADJUST (instrument_id) SELECT instrument_id FROM INSTRUMENT;
        
    UPDATE QUOTE_ADJUST set AMPLITUDE = (RAND() + 0.5);
    UPDATE QUOTE_ADJUST set SWITCHPOINT = ROUND((RAND()+.5)*750); 
END$$
DELIMITER ;