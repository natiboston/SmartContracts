pragma solidity ^0.4.16;


library PostLibrary{

  struct  PostSt{
      address post_owner;
      uint  intIdent; //Internal Identification
      string desctiption;
      address ownerPost; 
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
        post.adds[myday][in_position].pos_owner = post.post_owner;
        post.adds[myday][in_position].day = in_day;
        post.adds[myday][in_position].year = in_year;
        post.adds[myday][in_position].precio = in_valor;
        post.adds[myday][in_position].acept_temporal = true;
        post.adds[myday][in_position].acept_definitive = ib_definitive;


        is_add.postes[post.post_owner][myday].add_owner=is_add.add_owner;
        is_add.postes[post.post_owner][myday].pos_owner = post.post_owner;
        is_add.postes[post.post_owner][myday].day = in_day;
        is_add.postes[post.post_owner][myday].year = in_year;
        is_add.postes[post.post_owner][myday].precio = in_valor;
        is_add.postes[post.post_owner][myday].date_pago =now;
        is_add.postes[post.post_owner][myday].acept_temporal = true;
        is_add.postes[post.post_owner][myday].acept_definitive = ib_definitive;

        post.puja[myday].cont_curr_puja ++;

        // Si la actual puja esta llena, volvemos a empezar nueva puja
        if(post.puja[myday].cont_curr_puja == post.num_share_cycle){
          post.puja[myday].cont_curr_puja = 0;
          post.puja[myday].full_curr_puja = true;
        }


        // Llamada a pagar al poste esa cantidad.
        //transfer(is_add.postes[post.post_owner][myday].add_owner,
        //         is_add.postes[post.post_owner][myday].pos_owner,
        //         in_valor);
     
        // El anuncio paga al owner del post 
        is_add.postes[post.post_owner][myday].pos_owner.transfer(in_valor);
        
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
     //on_ok = func_returnMoney(post.post_owner, oa_ownerAdd, post.puja[myday].adjudicado_puja[on_pos].puja_done);
     

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


/////////////////////////////////////////////////////////////////////////
//
//      Postes
// 
/////////////////////////////////////////////////////////////////////////
contract contractAllPost {

  address public owner_post;
  mapping(address => uint) balances;

  function contractAllPost() payable{
    owner_post = msg.sender;
    balances[msg.sender] += msg.value;
  }
}


contract contractPost {


  address public owner;
  bool public result;
  string defaultAdd = "/Documents/add_default.avi";

  ////////////////////////////////////////////////////////////////////
  // For Cycling mode 
  uint constant cycle = 300 ; // number of seconds to share with another adds in repetetive modifier (5 min)
  uint constant uni_minim = 10 ; // Minimun unit length in seconds of an add => So max number of mimimum units adds in a cycle is 30.
                        //There could be and add with 3 uni_min (it lasts 30 second)
                        // There will be post with 6 uni de adds, 10 ads,  


  //mapping(address => PostLibrary.PostSt) allPost;
  //mapping(address => PostLibrary.AddvSt) allAdds;

  using PostLibrary for PostLibrary.PostSt;
  //using PostLibrary for PostLibrary.AddSt;
  PostLibrary.PostSt public post;


  modifier onlyOwner(){
      require (msg.sender == owner);
      _;
    }


  function contractPost(uint in_post, string iv_desc , uint in_nowyear,
                        uint in_lcycle, uint in_maxshare, 
                        uint in_inipuja, uint in_finpuja ) 
                        //returns (bool resultado){ 
      {
      // uint start = in_nowyear* 1 years;
      bool resultado =false;

      owner = msg.sender;
      post.intIdent = in_post ; //Internal Identification
      post.desctiption = iv_desc;
      post.ownerPost = msg.sender ; 
      post.long_cycle = in_lcycle; // i.e 300 seconds
      post.num_share_cycle = in_maxshare; // 1,2,3,5,10,15
      //post.priceUnit = in_price; //it depends of long_cycle and num_share_cycle

      resultado = true;
      resultado = PostLibrary.func_newPostPujaAllYear(post, in_nowyear, in_inipuja, in_finpuja); 
      
  }





  
  //func func_ClosePujaDay(uint day){
//
 // post.adds[myday].push(is_add.add_owner) ;
 // }


 // function func_returnMoney( address ia_postowner, address ia_addowner, uint in_valorpuja) return (bool ob_ok){
 //       msg.sender = ia_postowner;
 //       ia_addowner.send(in_valorpuja);
 // }
   



 // function func_AceptPuja(PostLibrary.AddSt storage is_add, uint in_year, uint in_day,
 //                         uint in_valor, bool ib_subst) 
 //      
 //      uint myday= in_year*1000 + in_day;
 //      
//
//
 //      returns ( uint on_result
//
//

      
   
}



///////////////////////////////////////////////////////////////////////////////
//
//       Advertisers
//
///////////////////////////////////////////////////////////////////////////////

contract contractAdvertiser{
  
    address public owner;
    advertiserSt public adver;
    
    //using PostLibrary for PostLibrary.AddSt;
    PostLibrary.AddSt[] adds;
    

    
    struct advertiserSt{
      string name;
      uint numAdds;
      uint balance;
    }


    function contractAdvertiser( string iv_name) public payable {
      owner = msg.sender;
      adver.name = iv_name;
      adver.numAdds = 0;
      adver.balance = msg.value;  //dinero inicial de la cuenta
    } 

    function func_newAdd(string iv_name, string iv_video ) returns (uint ) {
        uint len = adds.length -1;
        
        adds.push(PostLibrary.AddSt({ add_owner:owner,
                                      add_name: iv_name,
                                      add_movie: iv_video,
                                      add_id: len
                        }));
        adver.numAdds++;

        return  len;
    }

    function func_delAdd(uint idAd){
        delete adds[idAd];
        adver.numAdds--;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }
    
    function func_callPujarAdd(PostLibrary.AddSt storage is_add, PostLibrary.PostSt storage is_post , uint in_year, uint in_day,  uint in_valor) internal returns (uint on_result, uint on_numadds){  
        
        (on_result, on_numadds) = PostLibrary.func_Puja( is_add, is_post, in_year, in_day, in_valor);
        

        return (on_result, on_numadds);
    }


    

    function kill() onlyOwner {
        selfdestruct(owner);
    }

}




/*
function insertPost(uint in_numMax ) onlyOwner internal returns (uint) {
  
  result = false;

  // Initization 
  if ( placePost.dataPost[in_numMax].numNow  == 0  && ( placePost.dataPost[in_numMax].numMax == 0) ){
     result = PostLibrary.newType ( placePost.datapost[in_numMax],  in_numMax );
  }
  else
    result = true;
  ///////////////////////////////
  
  if (result) {
    result = PostLibrary.insert(placePost, in_numMax );

  }

  return result;
}
*/
/*
function funcLenPost(uint, t_postSt[]) constant returns (uint)  {
return 0;
}

function funcNewAddPost(uint, t_postSt[]) returns (uint)  {
return 0;
}

function funcModifyAddPost(uint, t_postSt[]) returns (uint)  {
return 0;
}

function funcGetInfoPost(uint, t_postSt[]) constant returns (uint)  {
return 0;
}

function funcDeletePost(uint, t_postSt[]) constant returns (uint)  {
return 0;
}
*/


 
 
/*


// ---- Categories for postes -------------
mapping (uint => categPostSt) categPost;
mapping (uint => typePostSt) typePost;

enum typePostE { Shared, Interval }  //
 

struct categPost1_St{
  string desctiption;
  uint  maxAdd;  //Max addvertasement to share the post
  uint  timeShareAdd; // Considered interval to share (1 min, 5 min, etc)
  float price;
}

struct categPost2_St{
  string desctiption;
  uint   longAdd; //multiple to 5 sc 
  float  price;
}

struct Post1{
  address         owner;
  categPost1_St   categ; 
  boolean         enable;
}

struct Post2{
  address         owner;
  categPost2_St   categ; 
  boolean         enable;
}


// ---- Postes -------------
Post1[] postes1;
Post2[] postes2;

*/

