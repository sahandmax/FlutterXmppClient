import 'package:flutter_test/flutter_test.dart';

import 'package:xmpp/xmpp.dart';

void main() {
  Xmpp xmpp = Xmpp();
  xmpp.CreateXmppConnection( server, port, username, password, resource)
  xmpp.setOnDeleteUserByJid((jid) {

  });
}
