pragma solidity ^0.4.16;

import "./Ownable.sol";
import "./ErrorLogger.sol";

/////////////////////////////////////////////////////////////////////////
//
//      Anunciantes
// 
/////////////////////////////////////////////////////////////////////////

contract contractAdvertiser  is Ownable, ErrorLogger {

    uint256 public numAdver;
    uint256 public numAdverActive;
    string defaultAd = "/Documents/add_default.avi";
 
        
    struct AdverSt{
      address ownerAd;
      string name;
      uint256 idAdver; //Internal Identification. It always growths
      uint256 numAds;       // Number of adds (actives or not)
      uint256 numAdsActive; // Number of active adds 
      uint256 maxAdsId;
      bool   active;
    }

    struct AdSt{
        address ownerAd;
        string nameAd;
        string  videolink;
        uint256 idAd;
        bool active;
    }

    // Una direccion corresponde a un anunciante => datos
    mapping (address => AdverSt) public Advers;   

    // Una direccion de un anunciante => conjunto de anuncios con clave unica (dada por numAds)
    mapping (address => mapping(uint256 => AdSt)) public Ads;  
  

    // ---------------------------------------------------------------------
    //                Advertiser 
    //----------------------------------------------------------------------
    function contractAdvertiser() public payable {
      numAdver = 0;  //dinero inicial de la cuenta
      numAdverActive = 0;
    } 


    function newAdver (address _owneraddv, string _name) onlyOwnerOrigin returns (uint256 on_idAdver){
    
        on_idAdver = 0;

        if(AdverExistsCheck(_owneraddv)){
            LogError(_ADV_EXIST, ADV_EXIST);
            return 0;
        }
               
        numAdver++;
        numAdverActive++;
        Advers[_owneraddv] = AdverSt(_owneraddv, _name, numAdver, 0, 0, 0, true );
        Ev_AdverCreated(_owneraddv);
        return numAdver;
    }

    

    function inactiveAdver (address _owneraddv) onlyOwnerOrigin returns (bool _ok){
    
       if(!AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST, ADV_NOTEXIST);
            return false;
        }

        if(!Advers[_owneraddv].active){
           LogError(_ADV_INACTV, ADV_INACTV);
            return false; 
        } 

        // 2. Desactive all of active Ads of this adver
        for (uint256 i = 1; i <= Advers[_owneraddv].maxAdsId; i++){
             inactiveAd(_owneraddv, Ads[_owneraddv][i].idAd);
        }
              
        // Desactive the Adver          
        Advers[_owneraddv].active = false;
        numAdverActive--;
        
        Ev_AdverInactive(_owneraddv, _ok);
        return true;
    }

    function activeAdver (address _owneraddv, bool flag_activeads) onlyOwnerOrigin returns (bool _ok){

       if(!AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST, ADV_NOTEXIST);
            return false;
        }

        if(AdverActiveCheck(_owneraddv)){
            LogError(_ADV_ACTV, ADV_ACTV);
           return false;
        }

                              
        // Active the Adver       
        Advers[_owneraddv].active = true;
        numAdverActive++;
        
        // 1. Active all of inactive Ads of this adver
        if(flag_activeads){
            for (uint256 i = 1; i <= Advers[_owneraddv].maxAdsId; i++){
                activeAd(_owneraddv, Ads[_owneraddv][i].idAd);
            }
        }

        Ev_AdverActive(_owneraddv, _ok);
        return true;
    }


    function removeAdver (address _owneraddv) onlyOwnerOrigin returns (uint256 _idAdver){
    
       _idAdver = 0;

       if(!AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST, ADV_NOTEXIST);
            return _idAdver;
        }
              
        //  1. Remove all its ads
        for (uint256 i = 1; i <= Advers[_owneraddv].maxAdsId; i++){
                removeAd(_owneraddv, Ads[_owneraddv][i].idAd);
        }
        
        _idAdver = Advers[_owneraddv].idAdver;
        delete(Advers[_owneraddv]);   

        numAdver--;
        numAdverActive--;    
        
        Ev_AdverRemoved(_owneraddv, _idAdver);
        return _idAdver;
    }
   
    
    // Checks if there exists a wallet at the specified address.
    function AdverExistsCheck(address _owneraddv) constant returns (bool active) {
        if ( Advers[_owneraddv].ownerAd == address(0x0) ) {
          return false;
        }
        return true;
    }

    function AdverActiveCheck(address _owneraddv) constant returns (bool active) {
        return  Advers[_owneraddv].active;
    }

    



    // ---------------------------------------------------------------------
    //                Ads
    //----------------------------------------------------------------------
    
  
    function newAd(address _owneraddv, string _name, string _video ) returns (uint ) {
        
        uint256 idAd ;
        
        if( !AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST, ADV_NOTEXIST);
            return 0;
        }
         
        //El nombre ya existe 
        if (searchNameAds (_owneraddv, _name, _video) >0 ){
            LogError(_ADD_NAMEXIST, ADD_NAMEXIST);
            return 0;
        }
        idAd = getNewIdAd(_owneraddv);

        // SE actualiza el maximo identificador de anuncios
        if (idAd > Advers[_owneraddv].maxAdsId){
            Advers[_owneraddv].maxAdsId= idAd; 
        } 
     
        Advers[_owneraddv].numAds++; 
        Advers[_owneraddv].numAdsActive++; 
                
        Ads[_owneraddv][idAd] = AdSt(_owneraddv, _name, _video, idAd, true );
        //Advers[_owneraddv].numAds++;
    
        Ev_AdCreated(_owneraddv, _video, idAd);  
        return  idAd;
    }


    // -- Inactive Ads ----
    function inactiveAd(address _owneraddv, uint256 _idAd) returns (bool _oresult ) {
        
        _oresult = false; 

        if( !AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST, ADV_NOTEXIST );
            return _oresult;
        }
        
        if( !AdExistsCheck(_owneraddv,_idAd) ){
            LogError(_ADD_NOTEXIST, ADD_NOTEXIST);
            return _oresult;
        }
        
        if( !AdActiveCheck(_owneraddv,_idAd)){
           LogError(_ADD_INACTV, ADD_INACTV);
            return _oresult; 
        } 

        Ads[_owneraddv][_idAd].active = false;

        Advers[_owneraddv].numAdsActive--; 
        
        _oresult = true;
        return _oresult;
        
    }

    // -- active Ads ----
    function activeAd(address _owneraddv, uint256 _idAd) returns (bool _oresult ) {
        
        _oresult = false; 

        if( !AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST,ADV_NOTEXIST);
            return _oresult;
        }
        
        if( !AdExistsCheck(_owneraddv,_idAd) ){
            LogError(_ADD_NOTEXIST, ADD_NOTEXIST);
            return _oresult;
        }
        
        if( AdActiveCheck(_owneraddv,_idAd)){
           LogError(_ADD_ACTV, ADD_ACTV);
           return _oresult; 
        } 


        Ads[_owneraddv][_idAd].active = true;

        Advers[_owneraddv].numAdsActive++; 
        
        _oresult = true;
        return _oresult;
        
    }

    // -- remove Ads ----
    function removeAd(address _owneraddv, uint256 _idAd) returns (bool _oresult ) {
        
        _oresult = false; 

        if( !AdverExistsCheck(_owneraddv)){
            LogError(_ADV_NOTEXIST, ADV_NOTEXIST);
            return _oresult;
        }
        
        if( !AdExistsCheck(_owneraddv,_idAd) ){
            LogError(_ADD_NOTEXIST, ADD_NOTEXIST);
            return _oresult;
        }
        
        delete(Ads[_owneraddv][_idAd]);

        Advers[_owneraddv].numAds--;
        Advers[_owneraddv].numAdsActive--; 

        // SE actualiza el maximo identificador de anuncios
        if (_idAd == Advers[_owneraddv].maxAdsId){
            Advers[_owneraddv].maxAdsId--; 
        } 
        
        _oresult = true;
        return _oresult;
        
    }


    // Checks if there exists a wallet at the specified address.
    function AdExistsCheck (address _owneraddv, uint _idAd) constant returns (bool exists) {
        if ( Ads[_owneraddv][_idAd].ownerAd != _owneraddv ) {
          return false;
        }
        return true;
    }

    // Checks if there exists a wallet at the specified address.
    function AdActiveCheck (address _owneraddv, uint _idAd) constant returns (bool exists) {
        return Ads[_owneraddv][_idAd].active;
    }

    
    // Get the first id for Ad available. If there is not any empty en Ads, it return the next one
    function getNewIdAd (address _owneraddv) constant returns (uint256 _newId) {
        uint256 i = 1;
          
        while( i <= Advers[_owneraddv].numAds  ) {
            if ( Ads[_owneraddv][i].ownerAd == address(0x0) ) {
               return i;
            }
            i++;   
        }
        return i;
    }


    function searchNameAds (address _owneraddv,  string  _name, string _video)  constant returns (uint256 _idAd) {
        uint256 id =1;
        bool found = false;
    
        while (id <= Advers[_owneraddv].numAds ) {
            if ( ( keccak256(_name)  == keccak256(Ads[_owneraddv][id].nameAd )) ||
                 ( keccak256(_video) == keccak256(Ads[_owneraddv][id].videolink )) )   {
              return id;
            }
            id++;
        }    
        // No ha encontrado el nombre .
        if(id > Advers[_owneraddv].numAds){
            return 0;
        }
    }    



/*
    function func_delAd(uint idAd){
        delete adds[idAd];
        adver.numAds--;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }
    
    function func_callPujarAd(PostLibrary.AdSt storage is_add, PostLibrary.PostSt storage is_post , uint in_year, uint in_day,  uint in_valor) internal returns (uint on_result, uint on_numadds){  
        
        (on_result, on_numadds) = PostLibrary.func_Puja( is_add, is_post, in_year, in_day, in_valor);
        

        return (on_result, on_numadds);
    }

*/
    

    function kill() onlyOwner {
        selfdestruct(owner);
    }

    // Triggered when openWallet succeeds.
    event Ev_AdverCreated (address indexed owner);
    event Ev_AdCreated(address indexed owner, string indexed video, uint256 indexed numAd);  
    event Ev_AdverRemoved (address indexed owner, uint256 indexed numAdver);
    event Ev_AdverInactive (address indexed owner, bool indexed result);
    event Ev_AdverActive (address indexed owner, bool indexed result);
   
}
