import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Order "mo:base/Order";

actor muro {
 public type Content = {
    #Text: Text;
    #Image: Blob;
    #Video: Blob;
};

public type Message = { 
  vote : Int;
  content : Content;
  creator : Principal;
};

private func keyHash(num : Nat) : Hash.Hash{
  return Text.hash(Nat.toText(num));
};

type Oder = Order.Order;
var messageId : Nat = 0;
let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, keyHash);

func compareMessage(mess1 : Message, mess2 : Message) : Order.Order {
if (mess1.vote == mess2.vote){
return #equal;
};
if (mess1.vote > mess2.vote){
  return #less;
};
return #greater;

};


  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
     Debug.print(debug_show ("ingrese su mensaje"));
     let nuevomensaje : Message = {
       vote = 0;
       content = c;
       creator = caller;    
     };
  messageId := messageId +1;    
  wall.put(messageId, nuevomensaje);
  Debug.print("fin del mensaje");
    return messageId;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    Debug.print("comienze getMenssage");
    if (messageId > wall.size() ){
        #err ("La id del mensaje no existe");

    } else {
        let message = wall.get(messageId);
        switch(message) {
            case(null) {
                #err("el mensaje esta vacio")
              };
            case(?message) {
                let res = wall.get(messageId);
                #ok(message);         
           };
        };
    }   
  };


// Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {

Debug.print("comienze la actualizacion");
if (messageId > wall.size()){
    
    #err("la id del mensaje no existe");
} else {
    let message = wall.get(messageId);
    switch(message){
        case(null){
           #err("este mensaje esta vacio")
        };
        case(?message){
            Debug.print("fin de la actualizacion");
            if (Principal.equal(message.creator, caller)){

                let updateMessage : Message = {

                    vote = 0;
                    content = c;
                    creator = caller;
            };
             let res = wall.replace(messageId, updateMessage);
             #ok(); 
            } else {#err("no es el dueño del mensaje")}
         
        }

    }
}
    
};

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
   if ((messageId <= 0) and (messageId < wall.size())){
    wall.delete(messageId);
    return #ok();
   } else{
    return #err("el mensaje solicitado no es valido");
   }
  };


  // Voting
   public func upVote(messageId : Nat) : async Result.Result<(), Text> {
     // Step 1: Get the message corresponding to the message Id
     switch(wall.get(messageId)){
       case(null){
         return #err("su voto no ha sido agregado.")
       };
       case(? message){
         // Step 2: Create a new message with the same fields expect for the vote (increased by 1)
         let newMessage = {
           creator = message.creator;
           content = message.content;
           vote = message.vote + 1;
         }; 
         // Step 3: Put the new message back into the datastructure
         wall.put(messageId, message);
         // Step 4: Return ok
         return #ok();
       };
     };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
     // Step 1: Get the message corresponding to the message Id
     switch(wall.get(messageId)){
       case(null){
         return #err("su voto no se ha descontado.")
       };
       case(? message){
         // Step 2: Create a new message with the same fields expect for the vote (increased by 1)
         let newMessage = {
           creator = message.creator;
           content = message.content;
           vote = message.vote - 1;
         }; 
         // Step 3: Put the new message back into the datastructure
         wall.put(messageId, message);
         // Step 4: Return ok
         return #ok();
       };
     };
  };

         



  // Get all messages
  public query func getAllMessages() : async [Message] {
    var messages = Buffer.Buffer<Message>(0);
    for (message in wall.vals()){
    messages.add(message);
    };
    return Buffer.toArray(messages);
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
  let array : [Message] = Iter.toArray(wall.vals());       
  return Array.sort<Message>(array, compareMessage);
  };
};