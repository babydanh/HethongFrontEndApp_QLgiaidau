import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    print('Sending request to public API...');
    final response = await dio.get('http://localhost:3000/api/v1/tournaments/public');
    print('Status Code: ${response.statusCode}');
    print('Data type: ${response.data.runtimeType}');
    
    final Map<String, dynamic> body = response.data;
    final List<dynamic> list = body['data'] ?? [];
    print('Found ${list.length} tournaments.');

    for (var json in list) {
      print('--- Tournament ---');
      print('ID: ${json['id']}');
      print('Name: ${json['name']}');
      print('Category: ${json['category']} (${json['category'].runtimeType})');
      
      // Try parsing exactly like Tournament.fromJson
      String? parsedCategory;
      if (json['category'] != null) {
        if (json['category'] is Map) {
          parsedCategory = json['category']['name']?.toString() ?? json['category']['id']?.toString();
        } else {
          parsedCategory = json['category'].toString();
        }
      }

      print('Parsed Category: $parsedCategory');
      print('Status: ${json['status']}');
      print('Format: ${json['format']}');
      print('Invite Code: ${json['inviteCode']}');
      print('Created By: ${json['createdBy']}');
      print('Max Participants/Teams: ${json['maxTeams'] ?? json['maxParticipants']}');
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
