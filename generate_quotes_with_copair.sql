CREATE DEFINER=`mike`@`localhost` PROCEDURE generate_quotes_with_copair3(IN loops INT, IN switch INT, IN amp INT)
  BEGIN
    /* This generate_quotes() is same as other except calls my copair() function */
    DECLARE this_instrument INT(11);
    DECLARE this_quote_date DATE;
    DECLARE this_quote_seq_nbr INT(11);
    DECLARE this_trading_symbol VARCHAR(15);
    DECLARE this_quote_time DATETIME;
    DECLARE this_ask_price DECIMAL(18,4);
    DECLARE this_ask_size INT(11);
    DECLARE this_bid_price DECIMAL(18,4);
    DECLARE this_bid_size INT(11);
    DECLARE loopcount INT(11);
    DECLARE maxloops INT(11);

    DECLARE new_quote_seq_nbr INT(11);

    /*variables for stockmarket.QUOTE_ADJUST values*/

    DECLARE qa_last_ask_price DECIMAL(18,4);
    DECLARE qa_last_ask_seq_nbr INT(11);
    DECLARE qa_last_bid_price DECIMAL(18,4);
    DECLARE qa_last_bid_seq_nbr INT(11);
    DECLARE qa_amplitude DECIMAL(18,4);
    DECLARE qa_switchpoint INT(11);
    DECLARE qa_direction TINYINT;
    DECLARE db_done INT
    DEFAULT FALSE;
    DECLARE cur1 CURSOR FOR SELECT * FROM STOCK_QUOTE /*WHERE INSTRUMENT_ID IN (SELECT INSTRUMENT_ID FROM INSTRUMENT)*/
                                     -- USE INDEX FOR ORDER BY (XK2_STOCK_QUOTE, XK4_STOCK_QUOTE)
                                     ORDER BY QUOTE_SEQ_NBR, QUOTE_TIME;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET db_done=1;

    SET maxloops=loops*1;

    -- Open the cursor and get appropriate values for this stock from QUOTE_ADJUST
    -- into local variables, save current actual value, output new values

    SET loopcount=0;

    OPEN cur1;

      quote_loop: LOOP

        IF (db_done OR loopcount=maxloops)
          THEN LEAVE quote_loop;
        END IF;

        FETCH cur1 INTO this_instrument,
                        this_quote_date,
                        this_quote_seq_nbr,
                        this_trading_symbol,
                        this_quote_time,
                        this_ask_price,
                        this_ask_size,
                        this_bid_price,
                        this_bid_size;

        SET new_quote_seq_nbr = (this_quote_seq_nbr * 2) + 1;
        /*all update logic goes here...first get stockmarket.QUOTE_ADJUST values into variables*/

        SELECT LAST_ASK_PRICE,
               LAST_ASK_SEQ_NBR,
               LAST_BID_PRICE,
               LAST_BID_SEQ_NBR,
               AMPLITUDE,
               SWITCHPOINT,
               DIRECTION
        INTO qa_last_ask_price,
             qa_last_ask_seq_nbr,
             qa_last_bid_price,
             qa_last_bid_seq_nbr,
             qa_amplitude,
             qa_switchpoint,
             qa_direction
        FROM QUOTE_ADJUST
        WHERE INSTRUMENT_ID=this_instrument;

        IF this_ask_price > 0 THEN /* it is an ask*/
          UPDATE QUOTE_ADJUST
            SET LAST_ASK_PRICE=this_ask_price
            WHERE INSTRUMENT_ID=this_instrument;

          UPDATE QUOTE_ADJUST
            SET LAST_ASK_SEQ_NBR=new_quote_seq_nbr
            WHERE INSTRUMENT_ID=this_instrument;

          IF qa_last_ask_price > 0 THEN     /* DOES THIS MEAN WE SHOULD ZERO OUT QUOTE_ADJUST TABLE BEFORE WE CALL THIS PROC? */
            /* then not first ask for this inst*/
            SET this_ask_price=qa_last_ask_price+( ABS(this_ask_price-qa_last_ask_price) *qa_amplitude*qa_direction);
            /* move the price up/down randomly by a tiny bit*/
          END IF;


        ELSE    /*it is a bid*/
            UPDATE QUOTE_ADJUST
              SET LAST_BID_PRICE=this_bid_price
              WHERE INSTRUMENT_ID=this_instrument;

            UPDATE QUOTE_ADJUST
              SET LAST_BID_SEQ_NBR=new_quote_seq_nbr
              WHERE INSTRUMENT_ID=this_instrument;

            IF qa_last_bid_price > 0 THEN
            /*not first bid for this inst*/
              SET this_bid_price=qa_last_bid_price+(ABS(this_bid_price-qa_last_bid_price)*qa_amplitude*qa_direction);
            END IF;
        /* end if this is an ask or a bid*/
        END IF;

         -- Do maintenance at the end of each iteration

        /* in all cases check and reset switchpoint if needed reset amplitude and update dates*/
        IF qa_switchpoint > 0 THEN
          /* if it is not time yet to change direction */
          UPDATE QUOTE_ADJUST
            SET SWITCHPOINT=SWITCHPOINT-1
            WHERE INSTRUMENT_ID=this_instrument ;
        ELSE
          /*switchpoint <=0, recalculate switchpoint and change direction */
          UPDATE QUOTE_ADJUST
            SET SWITCHPOINT= ROUND((RAND()+0.5)*switch)
            WHERE INSTRUMENT_ID=this_instrument;

			    UPDATE QUOTE_ADJUST
            SET DIRECTION= DIRECTION*-1
            WHERE INSTRUMENT_ID=this_instrument;
        END IF;

        UPDATE QUOTE_ADJUST
          SET AMPLITUDE=(RAND()+ amp)
          WHERE INSTRUMENT_ID=this_instrument;

        SET this_quote_date=CURDATE();
        /*you may want NOW() */
        SET this_quote_time=NOW();
        /* depending on your task */ /* now write out the record*/

        /* ######### My copair() function will get called here before new quote gets into the pool ############# */
        CALL copair1(this_instrument,
                this_quote_date,
                new_quote_seq_nbr,
                this_trading_symbol,
                this_quote_time,
                this_ask_price,
                this_ask_size,
                this_bid_price,
                this_bid_size);

        INSERT INTO STOCK_QUOTE_FEED
          VALUES(this_instrument,
                this_quote_date,
                new_quote_seq_nbr,
                this_trading_symbol,
                this_quote_time,
                this_ask_price,
                this_ask_size,
                this_bid_price,
                this_bid_size);

        SET loopcount=loopcount+1;

      END LOOP;
    CLOSE cur1;
END;
