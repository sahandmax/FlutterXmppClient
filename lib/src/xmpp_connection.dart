part of xmpp;



class StateResponse {
  String CheckResponse;
  String SendRequest;


  StateResponse(this.CheckResponse, this.SendRequest);
}

class XmppConnection {
  String _host;
  int _port;
  int _state = 0; // TODO make enum
  Socket _socket = null;
  XmppCallbacks xmppCallbacks;

  Completer _completer;

  XmppConnection(xmppCallbacks , String host, int port, String _username, String _password,
      String _resource) {
    _host = host;
    _port = port;
    this.xmppCallbacks = xmppCallbacks;
    List<int> authBytePlainText = [];
    authBytePlainText.add(0);
    authBytePlainText.addAll(utf8.encode(_username));
    authBytePlainText.add(0);
    authBytePlainText.addAll(utf8.encode(_password));
    _stateResponses = [
      new StateResponse('',
          '<stream:stream xmlns:stream="http://etherx.jabber.org/streams" version="1.0" xmlns="jabber:client" to="$_host" xml:lang="en" xmlns:xml="http://www.w3.org/XML/1998/namespace">'),
       new StateResponse(
              'stream:stream',
              '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">' + base64Encode(authBytePlainText) + '</auth>'),
      new StateResponse('',
          '<iq type="set"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><resource>$_resource</resource></bind></iq>'),
      new StateResponse('',
          '<presence xmlns="jabber:client"><priority>50</priority><x xmlns="vcard-temp:x:update"><photo /></x><c xmlns="http://jabber.org/protocol/caps" node="http://gajim.org" hash="sha-1" /></presence>'),
      new StateResponse('proceed',
          '<stream:stream xmlns:stream="http://etherx.jabber.org/streams" version="1.0" xmlns="jabber:client" to="chat.facebook.com" xml:lang="en" xmlns:xml="http://www.w3.org/XML/1998/namespace">'),
      new StateResponse('stream:stream', ''),
      new StateResponse('X-FACEBOOK-PLATFORM',
          '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="X-FACEBOOK-PLATFORM"></auth>'),
      new StateResponse('challenge', ''),
      new StateResponse('success',
          '<stream:stream xmlns:stream="http://etherx.jabber.org/streams" version="1.0" xmlns="jabber:client" to="$_host" xml:lang="en" xmlns:xml="http://www.w3.org/XML/1998/namespace">'),
      new StateResponse('stream:stream', ''),
      new StateResponse('stream:features',
          '<iq type="set" id="3"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><resource>fb_xmpp_script</resource></bind></iq>'),
      new StateResponse('jid',
          '<iq type="set" id="4" to="chat.facebook.com"><session xmlns="urn:ietf:params:xml:ns:xmpp-session"/></iq>'),
      new StateResponse('session', '<presence />'),
    ];
  }

  List<StateResponse> _stateResponses;

  void ProcessResponse(String response) {
    print('ProcessResponse');
    print(response);
    XmppParser.parse(xmppCallbacks , response,_socket,this);
//    // TODO
//    if (response.length > 0) {
//      print('xml parse...');


//      XmlElement myXmlTree = XML.parse(response);
//      print (myXmlTree.hasChildren);
//    }

    if (_state == -1) {
      return; // error
    }

    if (_state == 11) {
      _state++;
      _completer.complete();
      return;
    }

    if (_state == 12) {
      //print('presence info: $response');
      return;
    }


    if (_state == 3) {
      getRosters();

    }



    var stateResponse = _stateResponses[_state];

    if (stateResponse.CheckResponse.isEmpty ||
        response.contains(stateResponse.CheckResponse)) {
      if (_state == 4) {
        print("enigma occured");
        SecureSocket.secure(_socket,context: SecurityContext(withTrustedRoots: false)).then((secureSocket) {
          _socket = secureSocket;
          _socket.transform(Utf8Decoder()).listen(ProcessResponse);
          _state++;
          _socket.write(stateResponse.SendRequest);
        });
      } else if (_state == 6) {
        var challenge = response.substring(52); // TODO use a XML library
        challenge = challenge.substring(0, challenge.length - 12);

        var bytes = base64Decode(challenge);
        var str = new String.fromCharCodes(bytes);
        var uri = Uri.decodeFull(str);
        var method = uri.split('&')[1].substring(7);
        var nonce = uri.split('&')[2].substring(6);
        var inner = _getInnerChallengeResponse(method, nonce);
        var innerEncoded = base64Encode(inner.runes.toList());

        var challengeResponse =
            '<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl">$innerEncoded</response>';
        _state++;
        _socket.write(challengeResponse);
      } else {
        _state++;
        _socket.write(stateResponse.SendRequest);
      }
    } else {
      //_state = -1;
      // _completer.completeError("error");

    }
  }

  String _getInnerChallengeResponse(String method, String nonce) {
    // TODO this is untested
    return 'method=$method&nonce=$nonce&call_id=0&v=1.0';
  }

  Future SecureOpen() {
    _completer = new Completer();

    SecureSocket.connect(_host, _port , context: SecurityContext(withTrustedRoots: false) , onBadCertificate: (_) {return true;}).then((Socket socket) {
      _state = 0;
      _socket = socket;

      socket.transform(Utf8Decoder()).listen(ProcessResponse);

      ProcessResponse('');
    });

    return _completer.future;
  }

  Future Open() {
    _completer = new Completer();

    Socket.connect(_host, _port).then((Socket socket) {
      _state = 0;
      _socket = socket;

      socket.transform(Utf8Decoder()).listen(ProcessResponse);

      ProcessResponse('');
    });

    return _completer.future;
  }

  bool sendMessage(String messageId , String toJid, String body) {
    var msg =
        '<message xmlns="jabber:client" to="$toJid" type="chat" id="$messageId" ><body>$body</body></message>';
    try {
      _socket.write(msg);
      return true;
    }catch (e) {
      return false;
    }

  }

  void Close() {
    _socket.write('</stream:stream>');
    _state = 0;
  }

  void getArchivedMessagesMAM() {
    _socket.write("<iq type='set'><query xmlns='urn:xmpp:mam:1' /></iq>");
  }

  void getRosters() {
    _socket.write('<iq xmlns="jabber:client" type="get"><query xmlns="jabber:iq:roster" /></iq>');
  }

  void sendPresence(String to , String nick , String status , String presenceType) {
    _socket.write('<presence xmlns="jabber:client" to="$to" type="$presenceType"><nick xmlns="http://jabber.org/protocol/nick">$nick</nick><x xmlns="vcard-temp:x:update"><photo /></x><c xmlns="http://jabber.org/protocol/caps" node="http://gajim.org" ver="R4B7pGkn53HIHNxUVgndV2hvYsM=" hash="sha-1" /><status>$status</status></presence>');
  }
  
  void setFirstName(String name) {
    _socket.write('<iq xmlns="jabber:client" type="set" ><vCard xmlns="vcard-temp"><FN>$name</FN></vCard></iq>');
  }

  void getFirstName(String id) {
    _socket.write('<iq xmlns="jabber:client" type="get" to="$id"><vCard xmlns="vcard-temp" /></iq>');
  }

  getSocket() {
    return _socket;
  }
}
