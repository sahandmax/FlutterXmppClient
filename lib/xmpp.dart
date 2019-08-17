library xmpp;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';
import 'package:xml/xml.dart' as xml;

part 'src/xmpp_connection.dart';
part 'src/xmpp_parser.dart';
part 'src/xmpp_facebookConnection.dart';
part 'src/receivers/MamReceiver.dart';
part 'xmppcallbacks.dart';
/// A Calculator.
class Xmpp {

  /**
   * Returns newly created Xmpp connection.
   */
  static XmppConnection CreateXmppConnection(XmppCallbacks xmppCallbacks , String server, int port , String username , String password , String resource)
  {
    return new XmppConnection(server, port , username , password , resource);
  }

  /**
   * Returns newly created Facebook "Xmpp" connection.
   * Facebook chat (chat.facebook.com) implements a modified subset
   * of the xmpp protocol. In particular, an access token needs to be
   * acquired using the Facebook graph API before a connection to the
   * Facebook chat server can be made.
   */
  static FacebookXmppConnection CreateFacebookXmppConnection(String app_id, String access_token)
  {
    return new FacebookXmppConnection("chat.facebook.com", 5222, app_id, access_token);
  }

}