class House {
  final String id;
  final String name;
  final String address;
  final int userCount;
  final double dailyConsumption;
  final DateTime lastUpdated;

  House({
    required this.id,
    required this.name,
    required this.address,
    required this.userCount,
    required this.dailyConsumption,
    required this.lastUpdated,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      userCount: json['user_count'],
      dailyConsumption: json['daily_consumption'].toDouble(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'user_count': userCount,
      'daily_consumption': dailyConsumption,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
