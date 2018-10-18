pragma solidity ^0.4.16;

import "./PostLibrary.sol";

/////////////////////////////////////////////////////////////////////////
//
//      Postes
// 
/////////////////////////////////////////////////////////////////////////
contract contractAllPost {

  address public owner;
  mapping(address => uint) balances;

   modifier onlyOwner(){
      require (msg.sender == owner);
      _;
    }

  function contractAllPost() payable{
    owner = msg.sender;
    balances[msg.sender] += msg.value;
  }

  function kill() onlyOwner {
        selfdestruct(owner);
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

  //using PostLibrary for PostLibrary.PostSt;
  //using PostLibrary for PostLibrary.AddSt;
  uint  public numPujas;
  uint  public longPujas;

  PostLibrary.PostSt public post;
  event  LogIniPuja(uint lng_puja); 

  

  modifier onlyOwner(){
      require (msg.sender == owner);
      _;
    }

      address ownerPost; 
      uint long_cycle; // i.e 300 seconds
      uint num_share_cycle; // 1,2,3,5,10,15

  function contractPost(uint in_post, string iv_desc , uint in_nowyear,
                        uint in_lcycle, uint in_maxshare, 
                        uint in_inipuja, uint in_finpuja ) 
                        //returns (bool resultado){ 
      {
      // uint start = in_nowyear* 1 years;
      bool resultado =false;

      owner = msg.sender;
      post.post_owner = owner;
      post.intIdent = in_post ; //Internal Identification
      post.desctiption = iv_desc;
      post.ownerPost = msg.sender ; 
      post.long_cycle = in_lcycle; // i.e 300 seconds
      post.num_share_cycle = in_maxshare; // 1,2,3,5,10,15
      //post.priceUnit = in_price; //it depends of long_cycle and num_share_cycle

      resultado = true;
      //resultado = PostLibrary.func_newPostPujaAllYear(post, in_nowyear, in_inipuja, in_finpuja); 
      resultado = func_newPostPujaAllYear(post, in_nowyear, in_inipuja, in_finpuja); 

  }

  function func_newPostPuja(PostLibrary.PostSt storage is_post, uint in_year, uint in_day, uint in_inipuja,
                        uint in_finpuja  ) internal returns (bool){

        uint numday = in_year*1000 + in_day;
        
        //is_post.puja[numday].day_year = in_day;
        //is_post.puja[numday].ini_puja = in_inipuja;
        //is_post.puja[numday].fin_puja = in_finpuja;
        //is_post.puja[numday].full_curr_puja= false;
        //is_post.puja[numday].curr_puja = in_inipuja; // current_puja
        //is_post.puja[numday].cont_curr_puja = 0; //  CoCounter of the current_puja
        //is_post.puja[numday].end_date = (in_day + 30) *  1 days;
        is_post.puja[numday].cont_add = 0; //  ( 0 hasta el maximo para compartir )

        return true;
    }


    function func_newPostPujaAllYear (PostLibrary.PostSt storage is_post, uint in_year, 
                   uint in_inipuja, uint in_finpuja ) internal  returns (bool){

        uint numday = in_year*1000;
        
        for (uint i = numday+1;  i< numday+366; i++ ){
           func_newPostPuja(is_post, in_year, i, in_inipuja, in_finpuja );
           numPujas++;
        }
        
        return true;
    }

  
  function kill() onlyOwner {
        selfdestruct(owner);
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

