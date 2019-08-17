part of xmpp;

class MamReceiver {
  XmlElement xmlElement;

  MamReceiver(XmlElement xmlElement) {
    this.xmlElement = xmlElement;

    String type;
    String to_user;
    String from_user;
    String id;
    DateTime timeStamp;
    String body;

    for (XmlElement messageElement in xmlElement.children ) {
      switch (messageElement.name.toString()) {
        case "body":
          body = messageElement.text;
          break;
        case "message":
          for (XmlElement resultElement in messageElement.children) {
            switch (resultElement.name.toString()) {
              case "result":
                for(XmlElement forwardedElement in resultElement.children) {
                  switch (forwardedElement.name.toString()) {
                    case "forwarded":
                      for(XmlElement forwardChild in forwardedElement.children) {

                        switch (forwardChild.name.toString()) {
                            case "delay":
                              timeStamp = DateTime.parse(forwardChild.getAttribute("stamp"));
                            break;
                          case "message":
                            for (XmlElement innerMessageElement in forwardChild.children) {
                              switch (innerMessageElement.name.toString()) {
                                case "body":
                                  body = innerMessageElement.text;
                                  break;
                              }
                            }
                            type = "MessageType." + forwardChild.getAttribute("type");
                            to_user = forwardChild.getAttribute("to");
                            from_user = forwardChild.getAttribute("from");
                            id = forwardChild.getAttribute("id");
                            to_user = to_user.contains("/")? to_user.substring(0,to_user.indexOf("/")) : to_user;
                            from_user = from_user.contains("/") ? from_user.substring(0,from_user.indexOf("/")) : from_user;
                            MessageStatus messageStatus;
                            if (from_user.contains(DataHolder.profileModel.uniqufreindcode.toLowerCase() + "@"))
                              messageStatus = MessageStatus.sent;
                            else
                              messageStatus = MessageStatus.received;
                            try {
                              XmppSql.insertMessage(
                                  id,
                                  type,
                                  to_user,
                                  from_user,
                                  body,
                                  timeStamp.millisecondsSinceEpoch.toString(),
                                  messageStatus);
                            } catch (e) {

                            }
                            break;
                        }
                      }
                      break;
                  }
                }
                break;
            }
          }

       break;

      }
    }


  }


}