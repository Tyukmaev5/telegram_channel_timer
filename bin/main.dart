import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:telegram_bot/features/timer.dart'; 

void main() async { 
  final env = DotEnv()..load();
  final botToken = env['BOT_TOKEN'];

  if (botToken == null || botToken.isEmpty) {
    stderr.writeln('BOT_TOKEN is not set');
    exit(1);
  }

  final telegram = Telegram(botToken);
  final me = await telegram.getMe();

  final teledart = TeleDart(botToken, Event(me.username!));
  teledart.start();
  
  // Временно убираем проверку канала
  // final utils = Utils(teledart);
  //utils.checkChannel();

  // Используем TimerHelper
  final timerHelper = TimerHelper(teledart);
  teledart.onChannelPost().listen((message) {
    timerHelper.run(message);
  });
}
