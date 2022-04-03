import 'package:squareoffdriver/SquareOffMessage.dart';
import 'package:squareoffdriver/SquareOffCommunicationClient.dart';
import 'package:squareoffdriver/protocol/Answer.dart';
import 'package:squareoffdriver/protocol/model/RequestConfig.dart';

abstract class Command<T> {
  String code;
  String body;
  Answer<T> answer;

  Future<String> messageBuilder() async {
    return code + "#" + body + "*";
  }

  Future<void> send(SquareOffCommunicationClient client) async {
    String messageString = await messageBuilder();
    List<int> message = messageString.codeUnits;
    await client.send(message);
  }

  Future<T> request(
    SquareOffCommunicationClient client,
    Stream<SquareOffMessage> inputStream,
    [RequestConfig config = const RequestConfig()]
  ) async {
    Future<T> result = getReponse(inputStream);
    try {
      await send(client);
      T resultValue = await result.timeout(config.timeout);
      return resultValue;
    } catch (e) {
      if (config.retries <= 0) {
        throw e;
      }
      await Future.delayed(config.retryDelay);
      return request(client, inputStream, config.withDecreasedRetry());
    }
  }

  Future<T> getReponse(Stream<SquareOffMessage> inputStream) async {
    if (answer == null) return null;
    SquareOffMessage message = await inputStream
        .firstWhere((SquareOffMessage msg) => msg.getCode() == answer.code);
    return answer.process(message.getMessage());
  }
}