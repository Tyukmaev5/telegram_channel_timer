import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import '../../core/constants.dart';
import 'timer_service.dart';

class TimerHelper {
  final TeleDart bot;
  final TimerService service;

  TimerHelper(this.bot) : service = TimerService(bot);

  void run(Message event) {
    final text = (event.text ?? event.caption ?? '').trim();
    if (text.isEmpty) return;

    if (text.startsWith(BotSettings.setTimer)) {
      _handleSetTimer(event, text);
    } else if (text.startsWith(BotSettings.stopTimer)) {
      service.stopTimer(event.chat.id);
    } else if (text.startsWith(BotSettings.help)) {
      _handleHelp(event);
    }
  }

  Future<void> _handleSetTimer(Message event, String text) async {
    final args = text.replaceFirst(BotSettings.setTimer, '').trim();
    final exampleDateTime = _formatNow();

    if (args.isEmpty) {
      await bot.sendMessage(
        event.chat.id,
        '❗ Пожалуйста, укажи дату, время и название.\n'
        'Пример:\n'
        '${BotSettings.setTimer} $exampleDateTime "Название таймера"',
      );
      return;
    }

    final regex = RegExp(r"""^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+['"](.+)['"]$""");
    final match = regex.firstMatch(args);

    if (match == null) {
      await bot.sendMessage(
        event.chat.id,
        '❗ Неверный формат.\n'
        'Пример:\n'
        '${BotSettings.setTimer} $exampleDateTime "Название таймера"',
      );
      return;
    }

    final datePart = match.group(1)!;
    final timePart = match.group(2)!;
    final title = match.group(3)!;

    final endDateTime = DateTime.parse('${datePart}T$timePart:00');

    await service.startTimer(
      chatId: event.chat.id,
      title: title,
      endDateTime: endDateTime,
    );
  }

  Future<void> _handleHelp(Message event) async {
    final exampleDateTime = _formatNow();
    await bot.sendMessage(
      event.chat.id,
      'Для запуска таймера укажи дату, время и название.\n'
      'Пример:\n'
      '${BotSettings.setTimer} $exampleDateTime "Название таймера"',
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatNow() {
    final now = DateTime.now();
    final y = now.year;
    final m = _twoDigits(now.month);
    final d = _twoDigits(now.day);
    final hh = _twoDigits(now.hour);
    final mm = _twoDigits(now.minute);
    return '$y-$m-$d $hh:$mm';
  }
}