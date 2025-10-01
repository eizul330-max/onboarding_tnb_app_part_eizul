// my_azure_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// Use the public IP and the correct port (4000)
const String _baseUrl = 'http://20.255.50.177:4000';

class AzureApiService {
  Future<String> sayHelloFromApi() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hello'));
      
      if (response.statusCode == 200) {
        // Assuming your API returns a JSON object
        final data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception('Failed to load data from API. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the Azure API: $e');
    }
  }
}