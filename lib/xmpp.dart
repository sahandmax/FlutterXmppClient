library xmpp;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';
import 'package:xml/xml.dart' as xml;

part 'src/xmpp_connection.dart';
part 'src/xmpp_parser.dart';
part 'src/receivers/MamReceiver.dart';
part 'xmppcallbacks.dart';
/// A Calculator.
class Xmpp {
  XmppCallbacks xmppCallbacks = new XmppCallbacks();
  /**
   * Returns newly created Xmpp connection.
   */
  XmppConnection CreateXmppConnection(String server, int port , String username , String password , String resource)
  {
    return new XmppConnection(xmppCallbacks, server, port , username , password , resource);
  }

  void setOnDeleteUserByJid(Function(String) f) {
    xmppCallbacks.onDeleteUserByJid = f;
  }

}