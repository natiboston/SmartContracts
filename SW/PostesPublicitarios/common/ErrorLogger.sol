pragma solidity ^0.4.6;
/*
 * ErrorLogger
 *
 * Allows to log errors as events
 */
contract ErrorLogger {

	string constant PST_EXIST= "Post already exists";
	uint16 constant _PST_EXIST = 2000;

	string constant PST_NOTEXIST= "Post does not exist";
	uint16 constant _PST_NOTEXIST = 2001;

	string constant PST_ACTV= 'Post is already active';
	uint16 constant _PST_ACTV = 2002;

	string constant PST_INACTV= 'Post is already inactive';
	uint16 constant _PST_INACTV = 2003;

	//------------------------------
	string constant ADV_EXIST= "Advertiser already exists";
	uint16 constant _ADV_EXIST = 4000;

	string constant ADV_NOTEXIST= 'Advertiser does not exists';
	uint16 constant _ADV_NOTEXIST = 4001;

	string constant ADV_INACTV= 'Adverstiser is already inactive';
	uint16 constant _ADV_INACTV = 4002;

	string constant ADV_ACTV= 'Adverstiser is already active';
	uint16 constant _ADV_ACTV = 4003;

	string constant ADV_NOTOPE  = 'Advertiser not operative';
	uint16 constant _ADV_NOTOPE = 4004;

	string constant ADV_NOMONEY  = 'Advertiser doesn not  enough money';
	uint16 constant _ADV_NOMONEY = 4005;


    //--------------------------------------------------------
	string constant ADD_INACTV= 'Add is already inactive';
	uint16 constant _ADD_INACTV = 5002;

	string constant ADD_ACTV= 'Add is already active';
	uint16 constant _ADD_ACTV = 5003;

	string constant ADD_EXIST= 'Add already exists';
	uint16 constant _ADD_EXIST = 5004;

	string constant ADD_NOTEXIST= 'Add doesn not exist';
	uint16 constant _ADD_NOTEXIST = 5005;

	string constant ADD_NAMEXIST= 'The name for the add already exists';
	uint16 constant _ADD_NAMEXIST = 5006;
	
	string constant ADD_NOTOPE= 'Adverstiser is not operative';
	uint16 constant _ADD_NOTOPE = 5007;


	//------------------------------

	string constant PUJA_INACTV= 'Puja already inactive';
	uint16 constant _PUJA_INACTV = 6000;

	string constant PUJA_ACTV= 'Puja already active';
	uint16 constant _PUJA_ACTV = 6001;

	string constant PUJ_EXIST= 'Puja already exists';
	uint16 constant _PUJ_EXIST = 6002;

	string constant PUJ_NOTEXIST= 'Puja doesnt exist';
	uint16 constant _PUJ_NOTEXIST = 6003;

	string constant PUJ_NOTOPE= 'Puja no operative';
	uint16 constant _PUJ_NOTOPE = 6004;

	string constant PUJ_EXPIRED= 'Puja expired';
	uint16 constant _PUJ_EXPIRED = 6005;

	string constant PUJ_TOOLOW= 'Puja too low';
	uint16 constant _PUJ_TOOLOW = 6006;

	string constant PUJ_FULL= 'Puja full';
	uint16 constant _PUJ_FULL = 6007;

	string constant PUJ_NOACEPT= 'Puja not acepted';
	uint16 constant _PUJ_NOACEPT = 6008;

	string constant PUJ_CLOSED= 'Puja closed';
	uint16 constant _PUJ_CLOSED = 6009;
	
	string constant PUJ_MUSTCLOSED= 'Puja closed';
	uint16 constant _PUJ_MUSTCLOSED = 6010;	

	string constant PUJ_MUSTREDEF= 'Puja must have been redefined';
	uint16 constant _PUJ_MUSTREDEF = 6011;	

	string constant PUJ_TOOHIGH= 'Puja too high';
	uint16 constant _PUJ_TOOHIGH = 6012;	


	//------------------------------

	string constant WRG_DATES= 'Wrong Dates';
	uint16 constant _WRG_DATES = 9000;




	
	

  	event LogError(uint errorCode, string errorMessage);

  	// Default function
  	function () {
      throw;
  	}

}
