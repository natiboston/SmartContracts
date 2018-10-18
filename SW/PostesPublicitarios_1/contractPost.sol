pragma solidity ^0.4.16;

import "./Ownable.sol";
import "./ErrorLogger.sol";
import "./DateTime.sol";
//import "./PostLibrary.sol";

/////////////////////////////////////////////////////////////////////////
//
//      Postes
// 
/////////////////////////////////////////////////////////////////////////

contract contractPost  is Ownable, ErrorLogger, DateTime {

   struct  PostSt{
      address ownerPost; 
      uint256 idPost; //Internal Identification
      string desctiption;
      uint256 long_cycle; // i.e 300 seconds
      uint8 num_share_cycle; // 1,2,3,5,10,15
      bool active;
    } 

  struct PujaSt{
        uint256 ini_puja;
        uint256 fin_puja;
        uint256 curr_puja; // current_puja
        uint256 cont_curr_puja;
        uint256 end_date;
        uint256 cont_fin_puja; //  ( 0 hasta el maximo para compartir )
        bool active;
        bool expired ; //  Puja expired
        bool closed ; //  Puja closed
        
        mapping (uint16 => addsPujaSt) adds_puja; // identificador dentro del ciclo=> anuncio que puja
    }

  struct addsPujaSt{
        address add_owner;
        uint256 add_id;
        uint256 puja_done;
        uint256 puja_date;
        bool exist;
    }


  address public ownerOri;
  bool public result;
  uint256 public numPost;
  uint256 public numPostActive;

  uint16 public year1;
  uint16 public year2;
  uint8  public month1;
  uint8  public month2;
  uint8  public day1;
  uint8  public day2;


  // Una direccion de un poste => una configuracion de poste
  mapping (address => PostSt) public Postes;  
   
  mapping (uint256 => address ) public IdPostes;  
   
  
  // Un poste => Una configuracion de puja a nivel de año, mes, dia 
  mapping (address => mapping (uint16 => mapping (uint8 => mapping (uint8 => PujaSt)))) public  PostePuja;  
                


  
  ////////////////////////////////////////////////////////////////////
  // For Cycling mode 
  uint256 constant cycle = 300 ; // number of seconds to share with another adds in repetetive modifier (5 min)
  uint256 constant uni_minim = 10 ; // Minimun unit length in seconds of an add => So max number of mimimum units adds in a cycle is 30.
                        //There could be and add with 3 uni_min (it lasts 30 second)
                        // There will be post with 6 uni de adds, 10 ads,  

  //mapping(address => PostLibrary.PostSt) allPost;
  //mapping(address => PostLibrary.AddvSt) allAdds;

  //using PostLibrary for PostLibrary.PostSt;
  //using PostLibrary for PostLibrary.AddSt;
  uint256  public numPujas;
  uint256  public longPujas;

  //PostLibrary.PostSt public post;
  //PostSt public post;

  //event  LogIniPuja(uint lng_puja); 
 
  

 // modifier onlyOwner(){
 //     require (msg.sender == owner);
 //     _;
//    }

     

  function contractPost() {
      // uint start = in_nowyear* 1 years;
      ownerOri = tx.origin;
      numPost = 0;
      numPostActive = 0;
   }


  function newPost(address _ownerpost, string _desc, uint256 _lcycle, uint8 _maxshare) 
            onlyOwnerOrigin returns (uint256 on_post){
    
       uint256 newid;

       if(postExists(_ownerpost)){
            LogError(_PST_EXIST, PST_EXIST);
            return 0;
        }
        
        newid = getNewIdPost();
        
        Postes[_ownerpost] = PostSt(_ownerpost, newid, _desc, _lcycle, _maxshare, true );
        IdPostes[newid]=_ownerpost;
        
        numPost++;
        numPostActive++;

        Ev_PostCreated(_ownerpost);
        return numPost;
  }


  function removePost(address _ownerpost) onlyOwnerOrigin returns (uint256 _idPost){
    
       _idPost = 0;

       if(!postExists(_ownerpost)){
            LogError(_PST_NOTEXIST, PST_NOTEXIST);
            return _idPost;
        }
               
        _idPost = getIdPost(_ownerpost);
        delete(Postes[_ownerpost]); 
        delete(IdPostes[_idPost]);   

        numPost--;
        numPostActive--;    
        
        Ev_PostRemoved(_ownerpost, _idPost);
        return _idPost;
  }
   
    

  function getIdPost (address _ownerpost) constant returns (uint256){
      if(!postExists(_ownerpost)){
            LogError(_PST_NOTEXIST, PST_NOTEXIST);
            return 0;
      }
      return Postes[_ownerpost].idPost;  
  }


  function getNewIdPost () constant returns (uint256 _newId){
    uint256 i = 1;
          
    while( i <= numPost  ) {
            if ( IdPostes[i] == address(0x0) ) {
               return i;
            }
            i++;   
    }
        return i;
    
  }


  
  // Checks if there exists a wallet at the specified address.
  function postExists (address _ownerpost) constant returns (bool _exists) {
        if (Postes[_ownerpost].ownerPost == address(0x0)) {
           _exists = false; 
        }
        else{
          _exists = true;  
        }
    }


    function activePost(address _ownerpost) onlyOwnerOrigin returns (bool _ok){
    
      if(postExists(_ownerpost)){
            LogError(_PST_EXIST, PST_EXIST);
            return false;
      }
      if(Postes[_ownerpost].active ){
            LogError(_PST_ACTV, PST_ACTV);
            return false;
      }
        
      Postes[_ownerpost].active = true;         
      numPostActive++;
      _ok = true;
      
      Ev_PostActive(_ownerpost, _ok);
    }
    

   
   function inactivePost(address _ownerpost) 
            onlyOwnerOrigin returns (bool _ok){
    
      if(postExists(_ownerpost)){
            LogError(_PST_EXIST, PST_EXIST);
            return false;
      }
      if(!Postes[_ownerpost].active ){
            LogError(_PST_INACTV, PST_INACTV);
            return false;
      }
        
      Postes[_ownerpost].active = false;         
      numPostActive--;
      _ok = true;
      
      Ev_PostInactive(_ownerpost, _ok);
    }


    //----------------------------------------------------------------------------------
    //      Pujas
    //----------------------------------------------------------------------------------

    function newPuja(address _ownerpost, uint16 _year, uint8 _month, uint8 _day, uint256 _inipuja, uint256 _finpuja) returns (bool ob_result){
    
      uint256 puja_date = toTimestamp(_year, _month, _day, 0, 0, 0);
      uint256 expiration_date;

      uint8 daysmonth;    
      
      ob_result = false; 

      
      daysmonth = getDaysInMonth(_month, _year);
      expiration_date = puja_date + daysmonth * 1 days;

      year1= getYear(puja_date);
      month1= getMonth(puja_date);
      day1= getDay(puja_date);

      year2= getYear(expiration_date);
      month2= getMonth(expiration_date);
      day2= getDay(expiration_date);

      // 1.  Check 
      // 1.1 Post must exist
      if( !postExists(_ownerpost)){
              LogError(_PST_NOTEXIST, PST_NOTEXIST);
              return ob_result;
          }
      // 1.2 Correct date    
      if( (_year < 2018) || (_year > 2030) || (_month <1 ) || (_month>12) || (_day<1) || (_day>31)){
          LogError(_WRG_DATES, WRG_DATES);
              return ob_result;
      } 
      // 1.3 Puja not exist
      // Intentar hacer una libreria con esta funcion que es comun
      if ( PostePuja[_ownerpost][_year][_month][_day].ini_puja > 0 ) {
          LogError(_PUJ_EXIST, PUJ_EXIST);
          return ob_result;
      }
      
      
      PostePuja[_ownerpost][_year][_month][_day] = PujaSt(_inipuja, _finpuja, _inipuja, 0, expiration_date, 0, true, false, false);
      
      ob_result = true;    
      Ev_PujaCreated(_ownerpost,_year, _month, _day);   
    }


  function deletePuja(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) returns (bool ob_result){
    
    ob_result =false;
    // 1.  Check 
    // 1.1 Post must exist
    if( !postExists(_ownerpost)){
            LogError(_PST_NOTEXIST, PST_NOTEXIST);
            return ob_result;
        }
    // 1.2 Correct date    
    if( (_year < 2018) || (_year > 2030) || (_month <1 ) || (_month>12) || (_day<1) || (_day>31)){
        LogError(_WRG_DATES, WRG_DATES);
            return ob_result;
    } 
    // 1.3 Puja not exist
    if ( PostePuja[_ownerpost][_year][_month][_day].ini_puja == 0 ) {
        LogError(_PUJ_NOTEXIST, PUJ_NOTEXIST);
        return ob_result;
    }

    delete(PostePuja[_ownerpost][_year][_month][_day]);

    ob_result = true;
    year1= 0;
    month1= 0;
    day1= 0;
    year2= 0;
    month2= 0;
    day2= 0;

  }
  


  function  inactivePuja(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) returns (bool ){
    
    if( !postExists(_ownerpost)){
            LogError(_PST_NOTEXIST, PST_NOTEXIST);
            return false;
        }
    if( (_year < 2018) || (_year > 2030) || (_month <1 ) || (_month>12) || (_day<1) || (_day>31)){
        LogError(_WRG_DATES, WRG_DATES);
            return false;
    } 

    if(!PostePuja[_ownerpost][_year][_month][_day].active ){
        LogError(_PUJA_INACTV, PUJA_INACTV);
            return false;
    }

    // 1.3 Puja not exist
    if ( PostePuja[_ownerpost][_year][_month][_day].ini_puja == 0 ) {
        LogError(_PUJ_NOTEXIST, PUJ_NOTEXIST);
        return false;
    }

    PostePuja[_ownerpost][_year][_month][_day].active = false;
    
    Ev_PujaInactive(_ownerpost,_year, _month, _day);   
  }

  
  function activePuja(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) returns (bool ){
    
    if( !postExists(_ownerpost)){
            LogError(_PST_NOTEXIST, PST_NOTEXIST);
            return false;
        }
    if( (_year < 2018) || (_year > 2030) || (_month <1 ) || (_month>12) || (_day<1) || (_day>31)){
        LogError(_WRG_DATES, WRG_DATES);
            return false;
    }

    // 1.3 Puja not exist
    if ( !pujaExistCheck(_ownerpost, _year, _month, _day )) {
        LogError(_PUJ_NOTEXIST, PUJ_NOTEXIST);
        return false;
    } 

    if(pujaActiveCheck(_ownerpost, _year, _month, _day)){
        LogError(_PUJA_ACTV, PUJA_ACTV);
        return false;
    }
    
    PostePuja[_ownerpost][_year][_month][_day].active = true;
    
    Ev_PujaActive(_ownerpost,_year, _month, _day);   
  }


  // fucntion to check if Puja Exists
  function pujaExistCheck(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) constant returns (bool ){
    if ( PostePuja[_ownerpost][_year][_month][_day].ini_puja == 0 ) {
        return false;
    }
    return true;
  } 

  // fucntion to check if Puja Exists
  function pujaActiveCheck(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) constant returns (bool ){
     return PostePuja[_ownerpost][_year][_month][_day].active;
  } 

  function pujaExpiredCheck(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) constant returns (bool ){
      uint256 puja_date = toTimestamp(_year, _month, _day, 0, 0, 0);
      uint256 expiration_date;
      uint8 daysmonth;    
      
      daysmonth = getDaysInMonth(_month, _year);
      expiration_date = puja_date + daysmonth * 1 days;
      if ( now > expiration_date  ){
        return true;
      }
      return false;
  }

     
  function kill() onlyOwner {
        selfdestruct(owner);
  }   

  // Triggered when openWallet succeeds.
  event Ev_PostCreated (address indexed post);
  event Ev_PujaCreated(address _ownerpost, uint256 indexed _year, uint256 indexed _month, uint256 indexed _day);  
  event Ev_PujaInactive(address _ownerpost, uint256 indexed _year, uint256 indexed _month, uint256 indexed _day);  
  event Ev_PujaActive(address _ownerpost, uint256 indexed _year, uint256 indexed _month, uint256 indexed _day);  
  event Ev_PostRemoved(address _ownerpost, uint256 _idPost);
  event Ev_PostActive(address _ownerpost, bool _ok);
  event Ev_PostInactive(address _ownerpost, bool _ok);
  

 
   
}


