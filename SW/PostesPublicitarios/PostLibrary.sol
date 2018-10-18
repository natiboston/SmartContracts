pragma solidity ^0.4.16;


library PostLibrary{

     struct  PostSt{
      address ownerPost; 
      uint  intIdent; //Internal Identification
      string desctiption;
      uint long_cycle; // i.e 300 seconds
      uint num_share_cycle; // 1,2,3,5,10,15
      //uint priceUnit; //it depends of long_cycle and num_share_cycle
      mapping (uint => PujaSt)  puja; // A nivel de año, día //uint : year*1000 + day
      mapping (uint => mapping(uint => pagoSt)) adds; // A nivel de año, día //uint : year*1000 + day y luego de ciclo
    }

    struct PujaSt{
        uint day_year;
        uint ini_puja;
        uint fin_puja;
        bool full_curr_puja ; // Se ha llenado entero con la nueva puja
        uint curr_puja; // current_puja
        uint cont_curr_puja;
        uint end_date;
        uint cont_add; //  ( 0 hasta el maximo para compartir )
        pujaStatusSt[] adjudicado_puja;  // A nivel de ciclo compartido. Pueden pujar por lo mismo hasta que se llene el cycle.. despues deben apostar mas para ocuparlo
    }

    struct AddSt{
        address add_owner;
        string add_name;
        string  add_movie;
        uint add_id; //inetranl identifier for the advertiser
        mapping (address => mapping(uint => pagoSt)) postes;  //en que postes estas, y dias se indica el precio y dias)
    }

    struct pagoSt{
        address add_owner;
        address pos_owner;
        uint day;
        uint year;
        uint precio;
        uint date_pago;
        bool acept_temporal;
        bool acept_definitive;
    }


    struct pujaStatusSt{
        address add_owner;
        uint add_id;
        uint puja_done;
        uint puja_date;
    }

/*
    function func_newPostPuja(PostSt storage is_post, uint in_year, uint in_day, uint in_inipuja,
                        uint in_finpuja  ) internal returns (bool){

        uint numday = in_year*1000 + in_day;
        
        is_post.puja[numday].day_year = in_day;
        is_post.puja[numday].ini_puja = in_inipuja;
        is_post.puja[numday].fin_puja = in_finpuja;
        is_post.puja[numday].full_curr_puja= false;
        is_post.puja[numday].curr_puja = in_inipuja; // current_puja
        is_post.puja[numday].cont_curr_puja = 0; //  CoCounter of the current_puja
        is_post.puja[numday].end_date = (in_day + 30) *  1 days;
        is_post.puja[numday].cont_add = 0; //  ( 0 hasta el maximo para compartir )
        return true;
    }


    function func_newPostPujaAllYear (PostSt storage is_post, uint in_year, 
                   uint in_inipuja, uint in_finpuja ) internal  returns (bool){

        uint numday = in_year*1000;
        
        for (uint i = numday+1;  i< numday+366; i++ ){
           func_newPostPuja(is_post, in_year, i, in_inipuja, in_finpuja );
        }
        return true;
    }
*/

    function func_AceptPuja( AddSt storage is_add, PostSt storage post,
      uint in_year, uint in_day,  uint in_position, uint in_valor, bool ib_definitive) 
           internal  returns (bool ob_result) {

        uint myday= in_year*1000 + in_day;
        ob_result = false;

        post.puja[myday].adjudicado_puja[in_position].add_owner = is_add.add_owner;
        post.puja[myday].adjudicado_puja[in_position].add_id = is_add.add_id;
        post.puja[myday].adjudicado_puja[in_position].puja_done = in_valor;
        post.puja[myday].adjudicado_puja[in_position].puja_date = now;
        

        post.adds[myday][in_position].add_owner = is_add.add_owner;
        post.adds[myday][in_position].pos_owner = post.ownerPost;
        post.adds[myday][in_position].day = in_day;
        post.adds[myday][in_position].year = in_year;
        post.adds[myday][in_position].precio = in_valor;
        post.adds[myday][in_position].acept_temporal = true;
        post.adds[myday][in_position].acept_definitive = ib_definitive;


        is_add.postes[post.ownerPost][myday].add_owner=is_add.add_owner;
        is_add.postes[post.ownerPost][myday].pos_owner = post.ownerPost;
        is_add.postes[post.ownerPost][myday].day = in_day;
        is_add.postes[post.ownerPost][myday].year = in_year;
        is_add.postes[post.ownerPost][myday].precio = in_valor;
        is_add.postes[post.ownerPost][myday].date_pago =now;
        is_add.postes[post.ownerPost][myday].acept_temporal = true;
        is_add.postes[post.ownerPost][myday].acept_definitive = ib_definitive;

        post.puja[myday].cont_curr_puja ++;

        // Si la actual puja esta llena, volvemos a empezar nueva puja
        if(post.puja[myday].cont_curr_puja == post.num_share_cycle){
          post.puja[myday].cont_curr_puja = 0;
          post.puja[myday].full_curr_puja = true;
        }


        // Llamada a pagar al poste esa cantidad.
        //transfer(is_add.postes[post.ownerPost][myday].add_owner,
        //         is_add.postes[post.ownerPost][myday].pos_owner,
        //         in_valor);
     
        // El anuncio paga al owner del post 
        is_add.postes[post.ownerPost][myday].pos_owner.transfer(in_valor);
        
        ob_result = true ;
   
      
    }


    //Busca la primer posición libre
    function func_UndoPuja( PostSt storage post, uint in_year, uint in_day,  uint in_valor) 
                          internal returns (uint vn_position, bool ob_result ) {
        uint i = 0;
        uint myday= in_year*1000 + in_day;
        uint vn_date = now;
    
        vn_position = 5555;
        ob_result = true;
              
        // Recorremos el ciclo hacia hasta encontrar la puja mas antigua con valor inferior
        for ( i=0; i< post.num_share_cycle; i++){
             if( ( post.puja[myday].adjudicado_puja[i].puja_done < in_valor) && 
                 ( post.puja[myday].adjudicado_puja[i].puja_date < vn_date )) {
                  
                  vn_position = post.puja[myday].adjudicado_puja[i].add_id;
                  vn_date = post.puja[myday].adjudicado_puja[i].puja_date;          
             }
        }
        // algo pasa. no hay posiciones posibles. Todas las pujas son la actual
        // ciclo con misma puja
        if (vn_position == post.num_share_cycle){
            ob_result = false;
            post.puja[myday].full_curr_puja = true; 
            
        }
        //on_ok = func_returnMoney(post.ownerpost, oa_ownerAdd, post.puja[myday].adjudicado_puja[on_pos].puja_done);
         
    }

  
   function func_Puja(AddSt storage  is_add, PostSt storage post , uint in_year, uint in_day,  uint in_valor) 
          internal returns ( uint on_result, uint on_numadds)  {
      
      uint myday= in_year*1000 + in_day;
      uint poscycle = post.puja[myday].cont_add;
      uint vn_position; // position in the cycle;
      bool vb_definitive;  // valor de puja definitiva
      bool vn_result;


      on_result =0;
      on_numadds = post.puja[myday].cont_add;


      if ( in_valor  < post.puja[myday].ini_puja    ) {
        on_result = 10;
        return;
      }
      // Si ha alcanzado la fecha tope  no se puede pujar
      if ( now >  post.puja[myday].end_date * 1 days ) {
        on_result = 20;
        return ;
      }
      
      // 1.  Si está lleno el ciclo 
      if(post.puja[myday].cont_add  ==  post.num_share_cycle) {
        
        // 1.1 Hay que empezar nueva puja : Debe haber nueva oferta, se deshabilita el ultimo del ciclo que entro 
        //      y con puja inferior a la actual
        if (post.puja[myday].full_curr_puja ){

            // 1.1.1 nueva puja. El valor debe superar al anterior
            if (in_valor > post.puja[myday].curr_puja){

                // El valor de la puja cambia
                post.puja[myday].curr_puja = in_valor;

                if (in_valor ==  post.puja[myday].fin_puja){
                   vb_definitive = true;  
                }
                
                //nueva puja activa. Se permite rellenar el ciclo con la nueva puja 
                post.puja[myday].full_curr_puja = false; 
                
                // 1.1.1.1 Se deshecha la última puja
                (vn_position, vn_result) = func_UndoPuja( post, in_year, in_day, in_valor);
                //Devolver Dinero al anunciante    
                
                func_AceptPuja(is_add, post, in_year, in_day, vn_position, in_valor, vb_definitive);
                
                
                //post.puja[myday].cont_curr_puja = 1; 
            } //-- fin 1.1.1
            
            // 1.1.2  El valor de la puja no supera a la actual. Se deshecha
            else{
                 on_result = 50;  //Rechazada. Puja insuficiente
                 return ;
            } 
          
        } // fin 1.1  ciclo nuevo pero no nueva oferta

        // 1.2 El ciclo esta lleno pero la puja actual. no hay que aumentar
        else{
            // Se deshecha la última puja y Se acepta la nueva puja 
            
            // 1.2.1 Se deshecha la última puja
            (vn_position, vn_result) = func_UndoPuja(post, in_year, in_day, in_valor);
            //Devolver Dinero al anunciante    
                
                    
            // 1.2.1.1 Se acepta la puja 
            func_AceptPuja(is_add, post, in_year, in_day, vn_position, in_valor, vb_definitive);
        
        } // -- fin 1.1  nueva oferta 
  
      } // -- fin 1  Esta lleno el ciclo

      else {
        // 2. El ciclo no está lleno. SE acepta la oferta actual
        // Se acepta la nueva puja 
        // 1.2.1.1 Se acepta la puja 
        func_AceptPuja(is_add, post, in_year, in_day,poscycle, in_valor, vb_definitive);
        post.puja[myday].cont_add++;
        
        if (post.puja[myday].cont_add == post.num_share_cycle){
            post.puja[myday].full_curr_puja = true; 
        }    
      }

    }// -- fiin funcion

/*


//function newPlace( placePostSt storage is_placePost, string is_place )   returns (bool ob_result)  {
//      ob_result = false;
//
//      if(is_placePost.currentNum == 0 ){
//        is_placePost.currentNum ++ ;
//        is_placePost.total  ++;
//        is_placePost.place = is_place;
//        ob_result=true;
//      }
//    return ob_result;     
//  }
//
//  function newType ( typePostSt storage is_typePost, uint in_numMax )   returns (bool ob_result) {
//      ob_result=false;
//
//      if(is_typePost.numMax == 0 ){
//        is_typePost.numMax = in_numMax ;
//        is_typePost.numNow = 0 ;
//        ob_result=false;
//      }
//    return ob_result;     
//  }
//
//  function insert( placePostSt storage is_placePost, uint in_categ, PostSt is_post)   returns (bool ob_result) {
//    
//    uint vi_currentNum; 
//    ob_result = false;
//    
//    uint vi_maxNumPost = is_placePost.dataPost[in_categ].numMax;
//
//    if (vi_maxNumPost == in_categ ) {
//
//      // Get the current situation of is_placePost fot in_categ
//      vi_currentNum = is_placePost.dataPost[in_categ].postArr.length;
//
//     // If there is space for one more
//      if(vi_currentNum <= vi_maxNumPost ){
//
//       is_placePost.dataPost[in_categ].numNow ++;
//        is_placePost.dataPost[in_categ].intIdent = vi_currentNum;
//        is_placePost.dataPost[in_categ].desctiption = is_post.desctiption;
//        is_placePost.dataPost[in_categ].ownerPost = is_post.ownerPost;
//        is_placePost.dataPost[in_categ].priceUnit =  is_post.priceUnit;
//        ob_result = true;
//        }        
//     
//     } 
//    return ob_result;
//  }
 
*/
}  // -- End library

