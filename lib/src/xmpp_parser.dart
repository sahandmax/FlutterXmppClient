part of xmpp;

class XmppParser {
  String messages = "";
  XmppCallbacks xmppCallbacks;
  void parse(
      xmppCallbacks , String xmppResponse, Socket _socket, XmppConnection xmppConnection) {
    this.xmppCallbacks = xmppCallbacks;

    if(xmppResponse.split("<message ").length > 2)  {
      if ( xmppResponse[xmppResponse.length - 1] != ">")
      messages += xmppResponse;
      else {
//        if (messages == "")
//          messages = xmppResponse;
        messages += xmppResponse;
        xmppResponse = "<messages>" + messages + "</messages>";
        messages = "";

      }
    } else
      messages = "";


    try {
      if (xmppResponse.contains("<iq") && xmppResponse.contains("<presence")) {
        String iq = xmppResponse.substring(xmppResponse.indexOf("<iq"),
            xmppResponse.indexOf("</iq>") + "</iq>".length);
        String presence = xmppResponse.substring(xmppResponse.indexOf(
            "<presence",
            xmppResponse.indexOf("</presence>") + "</presence>".length));
        parse( xmppCallbacks, iq, _socket, xmppConnection);
        parse(xmppCallbacks ,presence, _socket, xmppConnection);
        return;
      }
      XmlDocument doc = xml.parse(xmppResponse);

      for (XmlElement xmlElement in doc.children) {
        print(xmlElement.name);
        switch (xmlElement.name.toString()) {
          case "presence":
            if (xmlElement.getAttribute("type") == "subscribe") {
              XmlBuilder builder = new XmlBuilder();
              builder.processing('xml', 'version="1.0"');
              builder.element('presence', nest: () {
                builder.attribute("xmlns", "jabber:client");
                builder.attribute('to', xmlElement.getAttribute("from"));
                builder.attribute('type', 'subscribed');
              });
              _socket.write(builder.build());
            }
            if (xmlElement.getAttribute("type") == "unsubscribe") {
              XmlBuilder builder = new XmlBuilder();
//              builder.processing('xml', 'version="1.0"');
//              builder.element('presence', nest: () {
//                builder.attribute("xmlns", "jabber:client");
//                builder.attribute('to', xmlElement.getAttribute("from"));
//                builder.attribute('type', 'unsubscribe');
//              });
//              _socket.write(builder.build());
              this.xmppCallbacks.onDeleteUserByJid(xmlElement.getAttribute("from"));

              builder = new XmlBuilder();
              builder.processing('xml', 'version="1.0"');
              builder.element('presence', nest: () {
                builder.attribute("xmlns", "jabber:client");
                builder.attribute('to', xmlElement.getAttribute("from"));
                builder.attribute('type', 'unsubscribed');
              });
              _socket.write(builder.build());
            }

            break;
          case "message":
            String body = "";
            String id = xmlElement.getAttribute(
              "id",
            );
            String type = xmlElement.getAttribute("type");
            String to_user = xmlElement.getAttribute("to");
            String from_user = xmlElement.getAttribute("from");
            DateTime timeStamp = DateTime.now();
            bool isArchivedMessage = false;

            for (XmlElement messageElement in xmlElement.children) {
              switch (messageElement.name.toString()) {
                case "body":
                  body = messageElement.text;
                  break;
                case "result":
                  id = messageElement.getAttribute("id");

                  if (messageElement.getAttribute("xmlns") == "urn:xmpp:mam:1") {
                    MamReceiver(messageElement);
                    isArchivedMessage = true;
                  }


                  break;
                case "delay":
                  timeStamp = DateTime.parse(
                    messageElement.getAttribute("stamp"),
                  );
              }
            }
            if (isArchivedMessage == false)
            XmppSql.insertMessage(
                id,
                type,
                to_user,
                from_user,
                body,
                timeStamp.millisecondsSinceEpoch.toString(),
                MessageStatus.received);
            break;

          case "iq":
            for (XmlElement iqElement in xmlElement.children) {
              switch (iqElement.name.toString()) {
                case "query":
                  if (iqElement.getAttribute("xmlns") == "jabber:iq:roster") {
                    XmppSql.getUsersList().then((users) {
                      print("get user occured");
                      if (iqElement.toString() != "")
                        for (User user in users) {
                          if (!iqElement.toString().contains(user.jid)) {
                            print("inner element" + iqElement.text);
                            print("delete jid : " + user.jid);
                            XmppSql.deleteUserByJid(user.jid);
                          }
                        }
                    });
                    for (XmlElement itemElement in iqElement.children) {
                      xmppConnection
                          .getFirstName(itemElement.getAttribute("jid"));
                      SubscriptionType subscriptionType =
                          AdditionalTools.getEnumFromString(
                        SubscriptionType.values,
                        itemElement.getAttribute("subscription"),
                      );
                      if (subscriptionType == SubscriptionType.none) {
                        XmppSql.deleteUserByJid(
                            itemElement.getAttribute("jid"));
                      } else {
                        XmppSql.insertUser(
                          itemElement.getAttribute("jid"),
                          "",
                          "",
                          StatusType.NotAvailable,
                          subscriptionType,
                        );
                      }
                    }
                  }
                  break;
                case "vCard":
                  if (iqElement.getAttribute("xmlns") == "vcard-temp") {
                    for (Object tempObject in iqElement.children) {
                      if (tempObject is XmlElement) {
                        XmlElement vCardProperyElement = tempObject;
                        switch (vCardProperyElement.name.toString()) {
                          case "FN":
                            XmppSql.updateUserFirstName(
                                vCardProperyElement.text,
                                xmlElement.getAttribute("from"));
                            break;
                        }
                      }
                    }
                  }
              }
            }
            break;
          case "messages":
            messages = "";
                  MamReceiver(xmlElement);
            break;
        }
      }
    } catch (e) {

      print("xmpp Exception : " + e.toString());
      print("fail to parse : " + xmppResponse);
    }
    MainStream.stream.sink.add(
        new MainStreamModel(streamModelType: MainStreamModelType.xmppRefresh));
  }
}
