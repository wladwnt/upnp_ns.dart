import "package:upnp_ns/dial.dart";

main() async {
  await for (DialScreen screen in DialScreen.find()) {
    var app = await screen.getCurrentApp();
    if (app != null) {
      print("Dial Screen ${screen.name} is running ${app}.");
    } else {
      print("Dial Screen ${screen.name} is idle.");
    }
  }
}
