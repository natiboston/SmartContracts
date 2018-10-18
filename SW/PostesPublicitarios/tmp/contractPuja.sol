 solidity ^0.4.16;

import "./contractPost.sol";
import "./contractAdvertiser.sol";
import "./MngWallet.sol";
import "./Ownable.sol";
import "./ErrorLogger.sol";


/////////////////////////////////////////////////////////////////////////
//
//      Pujas
// 
/////////////////////////////////////////////////////////////////////////

contract contractPuja  is Ownable, ErrorLogger, contractPost, contractAdvertiser, MngWallet {

	function contractPuja(){

	} 


	function requestAdvPuja(address _owneraddv, uint256 _idAd, address _ownerpost, 
	    uint16 _year, uint8 _month, uint8 _day, uint256 _valuepuja ) onlyOwnerAd(_owneraddv) returns (bool _ok) {
		
		bool result_ok = false;

		// 1 .----------   Check  ------------------------------------------
		// 1.1. Anunciante no existe o no está activo => no operativo 
		if( (!AdverExistsCheck(_owneraddv) ) ||  ( !AdverActiveCheck(_owneraddv)) ) {
			LogError(_ADV_NOTOPE, ADV_NOTOPE);
            return false;
		}
		
		// 1.2. Anuncio no existe o no activo => no operativo 
		if ( (!AdExistsCheck(_owneraddv, _idAd))  || (!AdActiveCheck(_owneraddv,_idAd)) ){
			LogError(_ADD_NOTOPE, ADD_NOTOPE);
            return false;	
		}
		
		// 5. Puja existe  y es activa
		if( (!PujaExistCheck(_ownerpost, _year, _month, _day)) || (!PujaActiveCheck(_ownerpost, _year, _month, _day)) ){
			LogError(_PUJ_NOTOPE, PUJ_NOTOPE);
            return false;		
		}

        // 6. Puja expirada 
        if( PujaExpiredCheck(_ownerpost, _year, _month, _day)){
			LogError(_PUJ_EXPIRED, PUJ_EXPIRED);

			// Antes se chequea si esta activa
			if ( !PostePuja[_ownerpost][_year][_month][_day].closed ){ 
				ClosePujaDay(_ownerpost, _year, _month, _day);
				LogError(_PUJ_CLOSED, PUJ_EXPIRED);
			}	
				 
            return false;	
		}
		
        // 7. check if the value is enough
		if ( _valuepuja < PostePuja[_ownerpost][_year][_month][_day].curr_puja){
			LogError(_PUJ_TOOLOW, PUJ_TOOLOW);
            return false;		
		}

		// 8. Si el valor de la puja actual es la definitiva y están todos los huecos llenos => Fin de Puja
		if (  PostePuja[_ownerpost][_year][_month][_day].closed  ){
			LogError(_PUJ_CLOSED, PUJ_CLOSED);
			return false;		
		}

		
        // 9. We check the wallet for the advertiser
        if( ( wallets[_owneraddv].balance  <  _valuepuja ) || 
           (!walletExists(_owneraddv) ) ) {
        	LogError(_ADV_NOMONEY, ADV_NOMONEY);
            return false;		
		}

		// 10. Value is superior to fin_puja => se limita a fin_puja
		if ( _valuepuja > PostePuja[_ownerpost][_year][_month][_day].fin_puja){
			
			_valuepuja = PostePuja[_ownerpost][_year][_month][_day].fin_puja;
		}

		// 2. -------------- ACEPT PUJA ------------------------------------------------
		
		result_ok = acceptAdvPuja (_owneraddv, _idAd, _ownerpost, _year, _month, _day, _valuepuja ); 
		if (!result_ok){
			LogError(_PUJ_NOACEPT, PUJ_NOACEPT);
		}

        return result_ok;			
	}	
    


	function acceptAdvPuja (address _owneraddv, uint256 _idAd, address _ownerpost,  
		uint16 _year, uint8 _month, uint8 _day, uint256 _valuepuja )onlyOwnerAd returns (bool result){

		uint8 idPos;
		address adver_oldpuja;
		uint256 ad_oldpuja;
		uint256 value_oldpuja;
		uint256 min_puja_done;

		// 1. Position para aceptar la puja (new or replace si la puja es mayor
		idPos = GetPositionAceptPuja( _ownerpost, _year, _month, _day, _valuepuja);

		// Si es superior es porque, o bien el ciclo estaba lleno con fin_puja (debería estar cerrada) o porque es necesario
		// haber definido una nueva valor de puja
		if (idPos > Postes[_ownerpost].num_share_cycle ){
			if(Postes[_ownerpost].cont_fin_puja == Postes[_ownerpost].num_share_cycle){
				// Antes se qhequeo que estaba activa y no estaba llena
				LogError(_PUJ_MUSTCLOSED, PUJ_MUSTCLOSED);
				return false;
			}
			LogError(_PUJ_MUSTREDEF, PUJ_MUSTREDEF);
			return false;	
		}

        // 2. Identificación del anunciante y anuncios desbancados
        adver_oldpuja = PostePuja[_ownerpost][_year][_month][_day].adds_puja[idPos].add_owner;
        
        // 2.1 Hueco no disponible. Se reemplaza
        if (adver_oldpuja !=address(0x0)){
	        ad_oldpuja = PostePuja[_ownerpost][_year][_month][_day].adds_puja[idPos].add_id;
    	    value_oldpuja = PostePuja[_ownerpost][_year][_month][_day].adds_puja[idPos].puja_done;
			
			//2.2 Devolucion de dinero al advertiser del anuncio en esa posición
            wallets[_owneraddv] += value_oldpuja;
            PostePuja[_ownerpost][_year][_month][_day].cont_curr_puja--;
        }
        
        
		// 3. Conseguir dinero del nuevo advertiser del anuncio. Antes se cheque que tenía suficiente
		wallets[_owneraddv] -= _valuepuja;
		

		// ----------------  PUJA ACEPTADA ----------------------------------------------
		// 4. Colocar el nuevo anuncio en la puja
		PostePuja[_ownerpost][_year][_month][_day].adds_puja[idPos] = addsPujaSt (_owneraddv, _idAd,_valuepuja, now(), true);
        
		//-- contabilizamos cuantas pujas intermedias y cuantas finales 
        if(_valuepuja == PostePuja[_ownerpost][_year][_month][_day].fin_puja){
        	PostePuja[_ownerpost][_year][_month][_day].cont_fin_puja++;	
        }
        else{
        	// 4.1 contadores (pujas)
           PostePuja[_ownerpost][_year][_month][_day].cont_curr_puja ++;
        }

        ////---------- PROCESAMIENTO PARA VER SI SE SIGUE CON LA MISMA PUJA, SE AUMENTA O SE CIERRA --------------------------
        // 5. Se llena el ciclo 

        // 5.1 Todo el ciclo con fin_puja
        if ( (PostePuja[_ownerpost][_year][_month][_day].cont_fin_puja ) == Postes[_ownerpost].num_share_cycle){
			result = ClosePujaDay(_ownerpost, _year, _month, _day);
			return result;
		}

        	
        // 5.2 =>  Se llena pero puede haber posibilidad de pujas mayores a la actual
        if ( ( PostePuja[_ownerpost][_year][_month][_day].cont_fin_puja + 
        	   PostePuja[_ownerpost][_year][_month][_day].cont_curr_puja ) == Postes[_ownerpost].num_share_cycle){
              
              	
              	// 5.1 get minima puja different to fin_puja. Si es fin_puja es que no hay mas pequeño
        	  	//min_puja_done = GetNewValuePuja(_ownerpost,_year,_month,_day);

        	  	// No encuentra ningun valor en el ciclo inferior a la puja => subimos puja
        	  	if(!ContinueSamePujaCheck(_ownerpost, _year, _month, _day)){
        	  		
        	  		// El siguiente valor de puja es superior a fin_puja => debería estar cerrada
        	  		if( PostePuja[_ownerpost][_year][_month][_day].curr_puja > PostePuja[_ownerpost][_year][_month][_day].fin_puja){
        	  			LogError(_PUJ_TOOHIGH, PUJ_TOOHIGH);
                        return false;
        	  		}
        	  		
        	  		// Aumentamos en '1' la puja
        	  		PostePuja[_ownerpost][_year][_month][_day].curr_puja++;
        	  	}	  	
        		
        }  

	} 


	function GetPositionAceptPuja(address _ownerpost, uint16 _year, uint8 _month, uint8 _day, uint256 _valuepuja)
	         constant returns (uint8 id) {
    
	    uint8 i = 1;
	    uint256 _minvalue =0;
	    uint256 _tmpvalue ;
	          
	    while( i <= Postes[_ownerpost].num_share_cycle  ) {

	    		if (PostePuja[_ownerpost][_year][_month][_day].adds_puja[i].puja_done < _valuepuja)
	               return i;
	         	i++;
	         }

	    return i;
		}
     	
    
    // Obtiene el valor más pequeño del ciclo por encima del curr_puja
    function ContinueSamePujaCheck (address _ownerpost, uint16 _year, uint8 _month, uint8 _day)
	         constant returns (bool _result) {
    
	    uint8 i = 1;
	          
	    while( i <= Postes[_ownerpost].num_share_cycle  ) {
	            
	            if (PostePuja[_ownerpost][_year][_month][_day].adds_puja[i].puja_done < PostePuja[_ownerpost][_year][_month][_day].curr_puja){
	               return true;
	            }
	                        
	            i++;   
		}
		return false;
	}
    
	function ClosePujaDay(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) returns (bool result){
		Postes[_ownerpost].closed = true;
		Postes[_ownerpost].active = false;
		return Postes[_ownerpost].closed;
	}

    function PujaExistCheck(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) constant returns (bool result){
    	if (PostePuja[_ownerpost][_year][_month][_day].ini_puja > 0 ){
    		return true;
    	}
    	return false;
    }


	function PujaActiveCheck(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) constant returns (bool result){
    	return PostePuja[_ownerpost][_year][_month][_day].active;
    }
    
    function PujaExpiredCheck(address _ownerpost, uint16 _year, uint8 _month, uint8 _day) constant returns (bool result){
    	if(now() > PostePuja[_ownerpost][_year][_month][_day].end_date){
    		PostePuja[_ownerpost][_year][_month][_day].expired = true;	
    	}
    	return PostePuja[_ownerpost][_year][_month][_day].expired;
    }




}


