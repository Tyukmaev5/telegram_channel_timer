class TimerUpdatePolicy {
  final Duration maxDuration;

  const TimerUpdatePolicy({this.maxDuration = const Duration(days: 7)});

  bool exceedsLimit(Duration remaining) => remaining > maxDuration;

  Duration nextDelay(Duration remaining) {
    // 2) если осталось больше 1 дня, то обновлять раз в день
    if (remaining > const Duration(days: 1)) {
      return const Duration(days: 1);
    }

    // 3) если осталось меньше 1 дня, то обновлять раз в 1 час
    if (remaining > const Duration(hours: 1)) {
      return const Duration(hours: 1);
    }

    // 4) если осталось меньше 1 часа, то обновлять каждые 20 минут
    return const Duration(minutes: 20);
  }

  /// Чтобы не проспать окончание таймера
  Duration capDelay(Duration delay, Duration remaining) {
    return delay < remaining ? delay : remaining;
  }
}
