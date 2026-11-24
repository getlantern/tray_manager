import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/tray_manager.dart';

class _Listener with TrayListener {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('tray_manager');
  final listener = _Listener();

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    trayManager.addListener(listener);
  });

  tearDown(() {
    trayManager.removeListener(listener);
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMessageHandler('flutter/assets', null);
  });

  Future<void> click(MenuItem item) => messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(kEventOnTrayMenuItemClick, {'id': item.id}),
        ),
        (_) {},
      );

  test('a click on the shown menu still works once it is replaced', () async {
    var clicked = false;
    final shown = MenuItem(label: 'shown', onClick: (_) => clicked = true);
    await trayManager.setContextMenu(Menu(items: [shown]));
    await trayManager.popUpContextMenu();
    await trayManager.setContextMenu(Menu(items: [MenuItem(label: 'next')]));

    await click(shown);

    expect(clicked, isTrue);
  });

  test('loads each menu icon asset once', () async {
    var loads = 0;
    messenger.setMockMessageHandler('flutter/assets', (_) async {
      loads++;
      return ByteData.sublistView(Uint8List.fromList([1, 2, 3]));
    });
    Menu menu() => Menu(items: [MenuItem(label: 'de', icon: 'flags/de.png')]);

    await trayManager.setContextMenu(menu());
    await trayManager.setContextMenu(menu());

    expect(loads, 1);
  });
}
