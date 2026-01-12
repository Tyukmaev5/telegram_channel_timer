import 'package:teledart/teledart.dart';
import '../core/constants.dart';

class Utils {
  final TeleDart bot;

  Utils(this.bot);
  void checkChannel() {
    bot.onMessage().listen((event) async { 
      // Если сообщение из канала, `event.chat.username` должен содержать username канала
      final chatUsername = event.chat.username;
      if (chatUsername != null &&
          !BotSettings.allowedChannels.contains('@$chatUsername')) {
        await bot.sendMessage(event.chat.id, '⛔ Бот предназначен для @tur_store');
        return;
      }
    });
  }
}
