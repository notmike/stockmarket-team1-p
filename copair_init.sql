CREATE TABLE `COPAIR_ASKS` (
  `INSTRUMENT_ID` int(11) NOT NULL,
  `QUOTE_DATE` date NOT NULL,
  `QUOTE_SEQ_NBR` int(11) NOT NULL,
  `TRADING_SYMBOL` varchar(15) DEFAULT NULL,
  `QUOTE_TIME` datetime DEFAULT NULL,
  `ASK_PRICE` decimal(18,4) DEFAULT NULL,
  `ASK_SIZE` int(11) DEFAULT NULL,
  PRIMARY KEY (`INSTRUMENT_ID`, `QUOTE_DATE`, `QUOTE_SEQ_NBR`)
);

CREATE TABLE `COPAIR_BIDS` (
  `INSTRUMENT_ID` int(11) NOT NULL,
  `QUOTE_DATE` date NOT NULL,
  `QUOTE_SEQ_NBR` int(11) NOT NULL,
  `TRADING_SYMBOL` varchar(15) DEFAULT NULL,
  `QUOTE_TIME` datetime DEFAULT NULL,
  `BID_PRICE` decimal(18,4) DEFAULT NULL,
  `BID_SIZE` int(11) DEFAULT NULL,
   PRIMARY KEY (`INSTRUMENT_ID`, `QUOTE_DATE`, `QUOTE_SEQ_NBR`)
);