// Message class for drawing purposes
class MyMessage {
  bool mine; // Whether a message is mine (legacy)
  String handle; // Sender handle (should replace boolean field)
  String text; // Message text

  MyMessage(this.text, this.handle, this.mine);

  MyMessage.fromNetworkMessage(NetworkMessage nm)
      : mine = false,
        handle = nm.handle,
        text = nm.text;
}

// TODO unify these two classes

// Network representation of a message
class NetworkMessage {
  String handle;
  int randomId;
  String text;
  // TODO Maybe insert time for rendering as well
  NetworkMessage(this.handle, this.randomId, this.text);

  NetworkMessage.fromMyMessage(MyMessage msg, int randomId, String handle)
      : handle = handle,
        randomId = randomId,
        text = msg.text;

  NetworkMessage.fromJson(Map<String, dynamic> json)
      : handle = json['handle'],
        randomId = json['randomId'],
        text = json['text'];

  Map<String, dynamic> toJson() => {
        'handle': handle,
        'randomId': randomId,
        'text': text,
      };
}
