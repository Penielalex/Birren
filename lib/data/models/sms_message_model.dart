class SmsMessageModel {
  final String? address;
  final String? body;
  final DateTime? date;

  const SmsMessageModel({
    this.address,
    this.body,
    this.date,
  });

  factory SmsMessageModel.fromMap(Map<dynamic, dynamic> map) {
    final rawDate = map['date'];
    return SmsMessageModel(
      address: map['address'] as String?,
      body: map['body'] as String?,
      date: rawDate is int
          ? DateTime.fromMillisecondsSinceEpoch(rawDate)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'body': body,
      'date': date?.millisecondsSinceEpoch,
    };
  }
}
