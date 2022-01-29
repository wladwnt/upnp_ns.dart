part of upnp_ns.server;

class UpnpServer {
  static final ContentType _xmlType =
      ContentType.parse('text/xml; charset="utf-8"');

  final UpnpHostDevice device;

  UpnpServer(this.device);

  Future handleRequest(HttpRequest request) async {
    Uri uri = request.uri;
    String path = uri.path;

    if (path == "/upnp/root.xml") {
      await handleRootRequest(request);
    } else if (path.startsWith("/upnp/services/") && path.endsWith(".xml")) {
      await handleServiceRequest(request);
    } else if (path.startsWith("/upnp/control/") && request.method == "POST") {
      await handleControlRequest(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }

  Future handleRootRequest(HttpRequest request) async {
    var urlBase = request.requestedUri.resolve("/").toString();
    var xml = device.toRootXml(urlBase: urlBase);
    request.response
      ..headers.contentType = _xmlType
      ..writeln(xml)
      ..close();
  }

  Future handleServiceRequest(HttpRequest request) async {
    var name = request.uri.pathSegments.last;
    if (name.endsWith(".xml")) {
      name = name.substring(0, name.length - 4);
    }
    var service = device.findService(name);

    if (service == null) {
      service = device.findService(Uri.decodeComponent(name));
    }

    if (service == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    } else {
      var xml = service.toXml();
      request.response
        ..headers.contentType = _xmlType
        ..writeln(xml)
        ..close();
    }
  }

  Future handleControlRequest(HttpRequest request) async {
    var bytes =
        await request.fold(<int>[], (List<int> a, List<int> b) => a..addAll(b));
    var xml = XmlDocument.parse(utf8.decode(bytes));
    var root = xml.rootElement;
    var body = root.firstChild;
    var service = device.findService(request.uri.pathSegments.last);

    if (service == null) {
      service = device
          .findService(Uri.decodeComponent(request.uri.pathSegments.last));
    }

    if (service == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }

    for (XmlNode node in body!.children) {
      if (node is XmlElement) {
        var name = node.name.local;
        UpnpHostAction act;
        try {
          act = service.actions.firstWhere((x) => x.name == name);
        } catch (e) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..close();
          return;
        }

        if (act.handler != null) {
          // TODO(kaendfinger): make this have inputs and outputs.
          await act.handler!({});
          request.response
            ..statusCode = HttpStatus.ok
            ..close();
          return;
        }
      }
    }
  }
}
