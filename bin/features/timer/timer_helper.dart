import 'dart:async';
import 'package:teledart/teledart.dart';
import '../../core/constants.dart';
import 'timer_update_policy.dart';

class TimerHelper {
  final TeleDart bot;
  final TimerUpdatePolicy policy;

  final Map<int, Timer> _activeTimers = {};
  final Map<int, int> _activeMessages = {}; // chatId -> messageId

  TimerHelper(this.bot, {TimerUpdatePolicy? policy})
    : policy = policy ?? const TimerUpdatePolicy();

  /// Главная точка входа — вызывай её из bot.onMessage()
  void run(event) {
    final text = event.text ?? '';
    // Проверяем, является ли сообщение командой (например, "/help")
    if (text.startsWith(BotSettings.setTimer)) {
      _handleSetTimer(event);
    } else if (text.startsWith(BotSettings.stopTimer)) {
      _handleStopTimer(event);
    } else if (text.startsWith(BotSettings.help)) {
      _handleHelp(event);
    }
  }

  Future<void> _handleSetTimer(event) async {
    final exampleDateTime =
        formatNow(); // Текущее время в формате "год-месяц-день часы:минуты"
    final args = event.text!.replaceFirst(BotSettings.setTimer, '').trim();

    if (args.isEmpty) {
      await bot.sendMessage(
        event.chat.id,
        '❗ Пожалуйста, укажи дату, время и название.\n'
        'Пример:\n'
        '${BotSettings.setTimer} $exampleDateTime "Название таймера"',
      );
      return;
    }

    final regex = RegExp(
      r"""^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+['"](.+)['"]$""",
    );
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

    DateTime endDateTime;
    try {
      endDateTime = DateTime.parse('$datePart $timePart:00');
    } catch (e) {
      await bot.sendMessage(
        event.chat.id,
        '❗ Не удалось распарсить дату/время. '
        'Убедись, что формат yyyy-MM-dd HH:mm',
      );
      return;
    }

    final now = DateTime.now();
    var remaining = endDateTime.difference(now);

    if (remaining.isNegative) {
      await bot.sendMessage(
        event.chat.id,
        '⚠ Таймер на прошедшее время не может быть запущен.',
      );
      return;
    }

    final sent = await bot.sendMessage(
      event.chat.id,
      '⏳ $title\nОсталось: ${_formatDuration(remaining)}',
    );

    final msgId = sent.messageId;
    final chatId = event.chat.id;

    _activeMessages[chatId] = msgId;

    _activeTimers[chatId]?.cancel(); // отменим предыдущий, если был

    _activeTimers[chatId] = Timer.periodic(Duration(minutes: 1), (timer) async {
      remaining = endDateTime.difference(DateTime.now());

      if (remaining.isNegative) {
        await bot.editMessageText(
          '✅ $title - время вышло!',
          chatId: chatId,
          messageId: msgId,
        );
        _activeTimers.remove(chatId);
        _activeMessages.remove(chatId);
        timer.cancel();
      } else {
        await bot.editMessageText(
          '⏳ $title\nОсталось: ${_formatDuration(remaining)}',
          chatId: chatId,
          messageId: msgId,
        );
      }
    });
  }

  Future<void> _handleStopTimer(event) async {
    final chatId = event.chat.id;

    if (_activeTimers.containsKey(chatId)) {
      _activeTimers[chatId]!.cancel();
      _activeTimers.remove(chatId);

      final msgId = _activeMessages.remove(chatId);
      if (msgId != null) {
        await bot.editMessageText(
          '🛑 Таймер остановлен.',
          chatId: chatId,
          messageId: msgId,
        );
      }

      await bot.sendMessage(chatId, '✅ Таймер успешно завершен.');
    } else {
      await bot.sendMessage(chatId, 'ℹ У тебя нет активных таймеров.');
    }
  }

  Future<void> _handleHelp(event) async {
    final exampleDateTime = formatNow();

    await bot.sendMessage(
      event.chat.id,
      'Для запуска таймера, укажи дату, время и название таймера.\n'
      'Пример:\n'
      '${BotSettings.setTimer} $exampleDateTime "Название таймера"',
    );
    return;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String formatNow() {
    final now = DateTime.now(); // локальное время сервера
    final y = now.year;
    final m = _twoDigits(now.month);
    final d = _twoDigits(now.day);
    final hh = _twoDigits(now.hour);
    final mm = _twoDigits(now.minute);
    return '$y-$m-$d $hh:$mm';
  }
}
