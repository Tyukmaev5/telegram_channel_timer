import 'dart:async';
import 'package:teledart/teledart.dart';

import 'timer_state.dart';
import 'timer_update_policy.dart';

class TimerService {
  final TeleDart bot;
  final TimerUpdatePolicy policy;

  final Map<int, ActiveTimerState> _stateByChat = {}; // chatId -> state

  TimerService(this.bot, {TimerUpdatePolicy? policy})
    : policy = policy ?? const TimerUpdatePolicy();

  ActiveTimerState? getState(int chatId) => _stateByChat[chatId];

  Future<void> startTimer({
    required int chatId,
    required String title,
    required DateTime endDateTime,
  }) async {
    final remaining = endDateTime.difference(DateTime.now());

    if (remaining.isNegative) {
      await bot.sendMessage(
        chatId,
        '⚠ Таймер на прошедшее время не может быть запущен.',
      );
      return;
    }

    if (policy.exceedsLimit(remaining)) {
      await bot.sendMessage(
        chatId,
        '⚠ Указанная дата превышает лимит таймера (7 дней).',
      );
      return;
    }

    // Если уже есть активный — остановим/перезапишем
    await stopTimer(chatId, silent: true);

    final sent = await bot.sendMessage(
      chatId,
      '⏳ $title\nОсталось: ${formatDuration(remaining)}',
    );

    final state = ActiveTimerState(
      chatId: chatId,
      messageId: sent.messageId,
      title: title,
      endDateTime: endDateTime,
    );

    _stateByChat[chatId] = state;
    _scheduleAdaptiveTick(state);
  }

  Future<void> stopTimer(int chatId, {bool silent = false}) async {
    final state = _stateByChat.remove(chatId);
    state?.timer?.cancel();

    if (state == null) {
      if (!silent) {
        await bot.sendMessage(chatId, 'ℹ У тебя нет активных таймеров.');
      }
      return;
    }

    if (!silent) {
      try {
        await bot.editMessageText(
          '🛑 Таймер остановлен.',
          chatId: chatId,
          messageId: state.messageId,
        );
      } catch (_) {
        // сообщение могли удалить/нельзя редактировать — игнорируем
      }

      await bot.sendMessage(chatId, '✅ Таймер успешно завершен.');
    }
  }

  void _scheduleAdaptiveTick(ActiveTimerState state) {
    state.timer?.cancel();

    final remaining = state.endDateTime.difference(DateTime.now());
    if (remaining.isNegative) {
      bot.editMessageText(
        '✅ ${state.title} - время вышло!',
        chatId: state.chatId,
        messageId: state.messageId,
      );
      _stateByChat.remove(state.chatId);
      return;
    }

    final delay = policy.capDelay(policy.nextDelay(remaining), remaining);

    state.timer = Timer(delay, () async {
      final newRemaining = state.endDateTime.difference(DateTime.now());

      if (newRemaining.isNegative) {
        try {
          await bot.editMessageText(
            '✅ ${state.title} - время вышло!',
            chatId: state.chatId,
            messageId: state.messageId,
          );
        } finally {
          _stateByChat.remove(state.chatId);
        }
        return;
      }

      try {
        await bot.editMessageText(
          '⏳ ${state.title}\nОсталось: ${formatDuration(newRemaining)}',
          chatId: state.chatId,
          messageId: state.messageId,
        );
      } catch (_) {
        // если не смогли отредактировать (удалили пост/нет прав) — можно остановить таймер
        // _stateByChat.remove(state.chatId);
        // return;
      }

      _scheduleAdaptiveTick(state);
    });
  }

  static String formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
