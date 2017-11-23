CREATE DEFINER=`mike`@`localhost` PROCEDURE copair(IN arg_instrument     INT, IN arg_quote_date DATE, IN arg_quote_seq_nbr INT,
                         IN arg_trading_symbol VARCHAR(15), IN arg_quote_time DATETIME, IN arg_ask_price DECIMAL(18, 4),
                         IN arg_ask_size       INT, IN arg_bid_price DECIMAL(18, 4), IN arg_bid_size INT)
  BEGIN
    DECLARE cp_a_instrument INT(11);
    DECLARE cp_a_quote_date DATE;
    DECLARE cp_a_quote_seq_num INT(11);
    DECLARE cp_a_trading_symbol VARCHAR(15);
    DECLARE cp_a_quote_time DATETIME;
    DECLARE cp_a_ask_price DECIMAL(18,4);
    DECLARE cp_a_ask_size INT(11);

    DECLARE cp_b_instrument INT(11);
    DECLARE cp_b_quote_date DATE;
    DECLARE cp_b_quote_seq_num INT(11);
    DECLARE cp_b_trading_symbol VARCHAR(15);
    DECLARE cp_b_quote_time DATETIME;
    DECLARE cp_b_bid_price DECIMAL(18,4);
    DECLARE cp_b_bid_size INT(11);

    DECLARE qa_last_ask_price DECIMAL(18,4);
    DECLARE qa_last_ask_seq_nbr INT(11);
    DECLARE qa_last_bid_price DECIMAL(18,4);
    DECLARE qa_last_bid_seq_nbr INT(11);
    DECLARE qa_switchpoint INT(11);
    DECLARE qa_direction TINYINT;

    DECLARE this_quote_seq_nbr INT(11);
    DECLARE this_ask_price DECIMAL(18,4);

    SELECT INSTRUMENT_ID,
           QUOTE_DATE,
           QUOTE_SEQ_NBR,
           TRADING_SYMBOL,
           QUOTE_TIME,
           ASK_PRICE,
           ASK_SIZE
      INTO cp_a_instrument,
           cp_a_quote_date,
           cp_a_quote_seq_num,
           cp_a_trading_symbol,
           cp_a_quote_time,
           cp_a_ask_price,
           cp_a_ask_size
        FROM COPAIR_ASKS
          WHERE INSTRUMENT_ID=0;

    SELECT INSTRUMENT_ID,
           QUOTE_DATE,
           QUOTE_SEQ_NBR,
           TRADING_SYMBOL,
           QUOTE_TIME,
           BID_PRICE,
           BID_SIZE
      INTO cp_b_instrument,
           cp_b_quote_date,
           cp_b_quote_seq_num,
           cp_b_trading_symbol,
           cp_b_quote_time,
           cp_b_bid_price,
           cp_b_bid_size
        FROM COPAIR_BIDS
          WHERE INSTRUMENT_ID=0;

    SELECT LAST_ASK_PRICE,
           LAST_ASK_SEQ_NBR,
           LAST_BID_PRICE,
           LAST_BID_SEQ_NBR,
           SWITCHPOINT,
           DIRECTION
      INTO qa_last_ask_price,
           qa_last_ask_seq_nbr,
           qa_last_bid_price,
           qa_last_bid_seq_nbr,
           qa_switchpoint,
           qa_direction
        FROM QUOTE_ADJUST
          WHERE INSTRUMENT_ID=0;

    SET this_quote_seq_nbr = arg_quote_seq_nbr + 1;

    /* if instr_id = 0 */
    IF arg_instrument = 0 THEN     /* Just running this on InstrumentID=0 */
      /* if quote is a ASK */
      IF arg_ask_price > 0 THEN
          /* if switch is < 100 and direction +1 */
          IF qa_switchpoint < 100 AND qa_direction > 0 THEN
          /* create an ASK and sell shares we already bought at competitive rate */
          /* track incoming ASKS to know what the cheapest one is, and insert that to stock-quote-feed */
            /* See if current copair ASK exists */
            IF exists (select * from COPAIR_ASKS) THEN
                /* if it exists */
                IF cp_a_ask_price > arg_ask_price THEN
                    SET this_ask_price = arg_ask_price - 0.01;
                    /* then update our current ASK to be below new ASK quote */
                    INSERT INTO STOCK_QUOTE_FEED
                      VALUES(arg_instrument,
                              arg_quote_date,
                              this_quote_seq_nbr,
                              arg_trading_symbol,
                              arg_quote_time,
                              this_ask_price,
                              arg_ask_size,
                              arg_bid_price,
                              arg_bid_size);
                    /* delete our old bid */
                    DELETE FROM STOCK_QUOTE_FEED WHERE INSTRUMENT_ID=arg_instrument AND QUOTE_TIME=cp_a_quote_time AND QUOTE_SEQ_NBR=cp_a_quote_seq_num AND BID_PRICE=cp_a_ask_price;
                    /* update quote_adjust w/ latest changes */

                    /* update our table to newest ask info */
                    UPDATE COPAIR_ASKS
                    SET QUOTE_SEQ_NBR=this_quote_seq_nbr, QUOTE_TIME=arg_quote_time, ASK_PRICE=this_ask_price, ASK_SIZE=arg_ask_size
                    WHERE INSTRUMENT_ID=arg_instrument;
                END IF;
            ELSE  /* No copair ASK yet, we need to create one */
                SET this_ask_price = arg_ask_price - 0.01;
                /* create new ask and beat incoming ask by 0.001 */
                INSERT INTO STOCK_QUOTE_FEED
                VALUES(arg_instrument,
                      arg_quote_date,
                      this_quote_seq_nbr,
                      arg_trading_symbol,
                      arg_quote_time,
                      this_ask_price,
                      arg_ask_size,
                      arg_bid_price,
                      arg_bid_size);
                /* update quote_adjust w/ latest changes */

                /* insert our new bid into our table */
                INSERT INTO COPAIR_ASKS VALUES(arg_instrument, arg_quote_date, this_quote_seq_nbr, arg_trading_symbol, arg_quote_time, this_ask_price, arg_ask_size);
            END IF;
          END IF;

      /* if quote is a bid */
      ELSEIF arg_bid_price > 1 THEN
        /* if switch is > 300 and direction +1 */
        IF qa_switchpoint > 300 AND qa_direction > 0 THEN
          /* if we have open bid */
          IF EXISTS(SELECT * FROM COPAIR_BIDS) THEN
            IF cp_b_bid_price < arg_bid_price THEN

              /* then beat existing bids by 0.001 for ASK size */
               INSERT INTO STOCK_QUOTE_FEED
               VALUES(arg_instrument,
                      arg_quote_date,
                      this_quote_seq_nbr,
                      arg_trading_symbol,
                      arg_quote_time,
                      arg_ask_price,
                      arg_ask_size,
                      arg_bid_price+0.01,
                      arg_bid_size);
               /* cancel our old bid */
               DELETE FROM STOCK_QUOTE_FEED WHERE INSTRUMENT_ID=arg_instrument AND QUOTE_TIME=cp_b_quote_time AND QUOTE_SEQ_NBR=cp_b_quote_seq_num AND BID_PRICE=cp_b_bid_price;
               /* update quote_adjust w/ latest changes */

               /* update our table to newest bid info */
              TRUNCATE COPAIR_BIDS;
              INSERT INTO COPAIR_BIDS VALUES(arg_instrument, arg_quote_date, this_quote_seq_nbr, arg_trading_symbol, arg_quote_time, arg_bid_price+0.01, arg_bid_size);
              END IF;
          ELSEIF NOT EXISTS(SELECT * FROM COPAIR_BIDS) THEN

                 /* create new bid and beat incoming bid by 0.001 */
                /* insert our new bid into our table */
               INSERT INTO COPAIR_BIDS VALUES(arg_instrument, arg_quote_date, this_quote_seq_nbr, arg_trading_symbol, arg_quote_time, arg_bid_price+0.01, arg_bid_size);
                /* update quote_adjust w/ latest changes */

               INSERT INTO STOCK_QUOTE_FEED
               VALUES(arg_instrument,
                      arg_quote_date,
                      this_quote_seq_nbr,
                      arg_trading_symbol,
                      arg_quote_time,
                      arg_ask_price,
                      arg_ask_size,
                      arg_bid_price+0.01,
                      arg_bid_size);
          END IF;

        END IF;
      END IF;
    END IF;
  END;
