
class Measurement {
  DateTime date;
  double? chest;
  double? back;
  double? waist;
  double? hips;
  double? leg;
  double? arm;
  double? weight;
  String? fatKg;
  String? hungerStatus;
  String? constipation;
  String? other;
  int? calorie;

  Measurement({
    required this.date,
    this.chest,
    this.back,
    this.waist,
    this.hips,
    this.leg,
    this.arm,
    this.weight,
    this.fatKg,
    this.hungerStatus,
    this.constipation,
    this.other,
    this.calorie,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'chest': chest,
      'back': back,
      'waist': waist,
      'hips': hips,
      'leg': leg,
      'arm': arm,
      'weight': weight,
      'fatKg': fatKg,
      'hungerStatus': hungerStatus,
      'constipation': constipation,
      'other': other,
      'calorie': calorie,
    };
  }

  static Measurement fromJson(Map<String, dynamic> json) {
    return Measurement(
      date: DateTime.parse(json['date']),
      chest: json['chest']?.toDouble(),
      back: json['back']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      leg: json['leg']?.toDouble(),
      arm: json['arm']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fatKg: json['fatKg'],
      hungerStatus: json['hungerStatus'],
      constipation: json['constipation'],
      other: json['other'],
      calorie: json['calorie']?.toInt(),
    );
  }
}